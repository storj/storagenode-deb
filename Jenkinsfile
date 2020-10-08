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
node {
stage('Build Repository') {
		checkout scm
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
	checkout scm
		def apt_repository = docker.build("apt-nginx", "-f ./apt-repository/nginx/Dockerfile .")
		def debian_buster_client = docker.build("debian-client", "-f ./docker/Dockerfile.debian-buster .")

		withDockerNetwork{ n ->
			apt_repository.withRun("--network ${n} --name apt-repository") { c ->
		    docker.image('tutum/dnsutils').inside("--network ${n}") {
			sh "cat /etc/resolv.conf || true"
		    sh "host apt-repository"
		}

debian_buster_client.inside("--network ${n} -u root:root") {
					sh "echo \"deb [trusted=yes] http://apt-repository buster-staging main\" > /etc/apt/sources.list.d/storjlabs.list"
					sh "apt-get update"
					sh "apt-cache search storagenode"
				}
			}
>>>>>>> 65fbac16a0a1b29dd589a1d0dcb1ae3ce11bef2c
		}
		finally {
		    sh 'git clean -fdx'
		    sh "rm -rf release"
		}
		
	    }
	    checkout scm
	    unstash 'storagenode-binaries'
	    unstash 'deb-package'
	    sh 'ls'
	    def binaries_server = docker.build("binaries-s", "-f ./docker/Dockerfile.binaries .")
	    def debian_buster_client = docker.image('debian:buster')
	    withDockerNetwork{ n ->
		binaries_server.withRun("--network ${n} --name binaries-server") { c ->
		    debian_buster_client.inside("--network ${n} -u root:root") {
			sh "apt-get update"
			sh 'apt-get install -y wget unzip'
	//		sh 'wget http://binaries-server'
			sh 'wget http://binaries-server/index.html'
			sh 'dpkg -i *.deb'
		    }
		}
	    }
	}	
	
	stage('Build Repository') {
	    checkout scm
	    def repoBuilderImage = docker.build("repo-builder", "-f ./apt-repository/Dockerfile.reprepro .")
	    repoBuilderImage.inside() {
		sh 'git clean -fdx'
		// check reprepro config
		sh "cd apt-repository && reprepro check buster-staging"
		// include new deb
		//unstash 'deb-package'
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
<<<<<<< HEAD
    }
    catch(err) {
	throw err
    }
    finally {
	sh "chmod -R 777 ." // ensure Jenkins agent can delete the working directory
	deleteDir()
    }
}

=======
}
>>>>>>> 65fbac16a0a1b29dd589a1d0dcb1ae3ce11bef2c
