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
		sh 'ls'
		def apt_repository = docker.build("apt-nginx", "-f ./apt-repository/nginx/Dockerfile .")
		def debian_buster_client = docker.build("debian-client", "-f ./docker/Dockerfile.debian-buster .")
		docker.build("binaries-s", "-f ./docker/Dockerfile.binaries .")

		withDockerNetwork{ n ->
		try {
			sh "docker run -d --network ${n} --name binaries-server binaries-s"
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
				sh "docker stop binaries-server"
				sh "docker rm binaries-server"
			}
		}
	}
}
