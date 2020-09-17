def withDockerNetwork(Closure inner) {
    try {
        networkId = UUID.randomUUID().toString()
        sh "docker network create ${networkId}"
	sh "docker network ls"
        inner.call(networkId)
    } finally {
        sh "docker network rm ${networkId}"
    }
}
stage('Build Package') {
    node {
	checkout scm
	def builderImage = docker.build("builder-image", "-f docker/Dockerfile.builder .")
	builderImage.inside {
	    sh 'cd packaging && dpkg-buildpackage -us -uc -b'
	    stash includes: '*.deb', name: 'deb-package'
	}
    }
}
// TODO
stage('Build binaries') {
    node {
	try {
	    checkout([$class: 'GitSCM', 
  		      branches: [[name: '*/master']], 
    		      doGenerateSubmoduleConfigurations: false, 
    		      extensions: [], 
    		      submoduleCfg: [], 
    		      userRemoteConfigs: [[ url: 'https://github.com/storj/storj' ]]
	    ])
	    docker.image('storjlabs/golang:1.15.1').inside("-u root:root") {
		sh 'ls'
		sh './scripts/release.sh build -o release/storagenode storj.io/storj/cmd/storagenode'
		sh './scripts/release.sh build -o release/storagenode storj.io/storj/cmd/storagenode-updater'
		sh 'ls ./release'
		stash includes: 'release/storagenode*', name: 'storagenode-binaries'
		sh 'rm -rf release'
	    }
	}
	catch(err) {
	    throw err
	}
	finally {
	    //deleteDir()
	}
    }
}

node {
    stage('Build Repository') {
	
	def repoBuilderImage = docker.build("repo-builder", "-f ./apt-repository/Dockerfile.reprepro .")
	repoBuilderImage.inside() {
	    sh 'git clean -fdx'
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
	
	def apt_repository = docker.build("apt-nginx", "-f ./apt-repository/nginx/Dockerfile .")
	def debian_buster_client = docker.build("debian-client", "-f ./docker/Dockerfile.debian-buster .")
	
	withDockerNetwork{ n ->
	    apt_repository.withRun("--network ${n} --name apt-repository") { c ->
		debian_buster_client.inside("--network ${n} -u root:root") {
		    sh "echo \"deb [trusted=yes] http://apt-repository buster-staging main\" > /etc/apt/sources.list.d/storjlabs.list"
		    sh "apt-get update"
		    sh "apt-cache search storagenode"
		}
	    }
	}
    }
}
