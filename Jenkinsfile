def withDockerNetwork(Closure inner) {
	try {
		networkId = UUID.randomUUID().toString()
		sh "docker network create ${networkId}"
		inner.call(networkId)
	} finally {
		sh "docker network rm ${networkId}"
	}
}

node {
	stage('Build Package') {
		checkout scm
		def builderImage = docker.build("builder-image", "-f docker/Dockerfile.builder .")
		builderImage.inside {
			sh 'cd packaging && BINARIES_SERVER="http://binaries-server" dpkg-buildpackage -us -uc -b'
			stash includes: '*.deb', name: 'deb-package'
		}
	}

	stage('Build binaries') {
	    docker.image('storjlabs/golang:1.15.1').inside("-u root:root") {
			try {
		    	checkout([$class: 'GitSCM',
  					branches: [[name: '*/master']],
    				doGenerateSubmoduleConfigurations: false,
    				extensions: [],
    			    submoduleCfg: [],
    			    userRemoteConfigs: [[ url: 'https://github.com/storj/storj' ]]
				])
				sh './scripts/release.sh build -o release/storagenode storj.io/storj/cmd/storagenode'
				sh './scripts/release.sh build -o release/storagenode-updater storj.io/storj/cmd/storagenode-updater'

				stash includes: 'release/storagenode*', name: 'storagenode-binaries'
			}
			catch(err) {
				throw err
			}
			finally {
				sh 'git clean -fdx'
				sh "rm -rf release"
			}
		}
	}

	stage('Build Repository') {
		checkout scm

		def repoBuilderImage = docker.build("repo-builder", "-f ./apt-repository/Dockerfile.reprepro .")
		repoBuilderImage.inside() {
			// check reprepro config
			sh "cd apt-repository && reprepro check buster-staging"
			// include new deb
			unstash 'deb-package'
			// for tests, we need to tell reprepro to not sign the packages
			sh 'sed -i \'/SignWith/d\' apt-repository/conf/distributions'
			sh 'cd apt-repository && reprepro includedeb buster-staging ../*.deb'
			}
		}

	stage('Test Repository') {
		unstash 'deb-package'
		unstash 'storagenode-binaries'
		sh 'ls release'
		def apt_repository = docker.build("apt-nginx", "-f ./apt-repository/nginx/Dockerfile .")
		def debian_buster_client = docker.build("debian-client", "-f ./docker/Dockerfile.debian-buster .")
		docker.build("storj-ci", "--pull https://github.com/storj/ci.git")
		docker.build("sim", "-f ./docker/Dockerfile.sim .")

		withDockerNetwork{ n ->
		try {
			sh "mkdir ./identity-files"
			sh "docker run -d --network ${n} --name storj-sim -u root:root -v `pwd`/identity-files:/identity-files sim"
			sh "docker run -d --network ${n} --name binaries-server -v `pwd`/release:/usr/share/nginx/html -w /usr/share/nginx/html nginx:latest"
			sh "docker exec binaries-server apt update"
			sh "docker exec binaries-server apt install -y zip"
			sh "docker exec binaries-server mv storagenode storagenode_linux_amd64"
			sh "docker exec binaries-server mv storagenode-updater storagenode-updater_linux_amd64"
			sh "docker exec binaries-server zip storagenode_linux_amd64 storagenode_linux_amd64"
			sh "docker exec binaries-server zip storagenode-updater_linux_amd64 storagenode-updater_linux_amd64"
			sh "ls ./identity-files"

			sh '/bin/bash -c \"docker logs storj-sim\" || true'
			docker.image('curlimages/curl').inside("--network ${n}") {
				sh (
					script: "while ! curl --output /dev/null --silent http://storj-sim:11000/minio/health/live; do sleep 1; done",
					label: "Wait for storj-sim to be ready"
				)
			}
			IDENTITY_DIR = sh (
				script: "docker exec storj-sim storj-sim network env STORAGENODE_9_DIR",
				returnStdout: true
			)

			sh "docker exec storj-sim cp -r ${STORAGENODE_9_DIR} /identity-files"
			sh "docker exec storj-sim ls /identity-files"
			sh "ls ./identity-files"
			apt_repository.withRun("--network ${n} --name apt-repository") { c ->
				debian_buster_client.inside("--network ${n} -u root:root") {
					sh "echo \"deb [trusted=yes] http://apt-repository buster-staging main\" > /etc/apt/sources.list.d/storjlabs.list"
					sh "apt-get update"
					sh 'apt-get install -y wget unzip debconf-utils'
					sh "apt-cache search storagenode"
					sh "/bin/bash -c 'cat tests/debconf/basic-install | debconf-set-selections'"
					sh "/bin/bash -c 'debconf-get-selections | grep storagenode'"
					sh "DEBIAN_FRONTEND=noninteractive BINARIES_SERVER=http://binaries-server apt install -y storagenode"
				}
			}
			} catch(err){throw err}
			finally {
				sh '/bin/bash -c "docker logs storj-sim" || true'
				sh "docker stop binaries-server || true"
				sh "docker rm binaries-server || true"
				sh "docker stop storj-sim || true"
				sh "docker rm storj-sim || true"
				sh "rm -f ./release/storagenode_amd64.zip"
				sh "rm -f ./release/storagenode-updater_amd64.zip"
				sh "rm -rf ./identity-files"
			}
		}
	}
}
