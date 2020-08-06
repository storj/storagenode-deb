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

pipeline {
	agent none
	stages {
		stage('Build Package') {
			agent {
				dockerfile {
					filename 'docker/Dockerfile.builder'
					dir '.'
				}
			}
			steps {
				sh 'cd packaging && dpkg-buildpackage -us -uc -b'
				stash includes: '*.deb', name: 'deb-package'
			}
		}
		// TODO
		/*stage('Test Package') {
			agent {
				dockerfile {}
			}
			steps {
				unstash 'deb-package'
			}
		}*/
		
		stage('Build Repository') {
			agent {
				dockerfile {
					filename './apt-repository/Dockerfile.reprepro'
					dir '.'
				}
			}
			steps {
				sh 'git clean -fdx'
				// check reprepro config
				sh "cd apt-repository && reprepro check buster-staging"
				// include new deb
				unstash 'deb-package'
				// for tests, we need to tell reprepro to not sign the packages
				sh 'sed -i \'/SignWith/d\' apt-repository/conf/distributions'
				sh 'cd apt-repository && reprepro includedeb buster-staging ../*.deb'
				sh 'ls'
			}
		}
		stage('Test Repository') {
			agent any
			steps {
				script {
					def apt_repository = docker.build("apt-nginx", "-f ./apt-repository/nginx/Dockerfile .")
					def debian_buster_client = docker.build("debian-client", "-f ./docker/Dockerfile.debian-buster .")
					apt_repository.withRun("--network ${n} --name apt-repository").inside("--network ${n}") {
					sh 'ls"
					sh "ls apt-repository"
					}

					withDockerNetwork{ n ->
						apt_repository.withRun("--network ${n} --name apt-repository") { c ->
							debian_buster_client.inside("""
								--network ${n} -u root:root
							""") {
								sh "echo \"deb [trusted=yes] http://apt-repository buster-staging main\" > /etc/apt/sources.list.d/storjlabs.list"
								sh "apt-get update"
								sh "apt-cache search storagenode"
							}
						}
					}
				}
			}
		}
	}
}
