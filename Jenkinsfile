def withDockerNetwork(Closure inner) {
    try {
        networkId = UUID.randomUUID().toString()
        sh "docker network create ${networkId}"
        inner.call(networkId)
    } finally {
        sh "docker network rm ${networkId}"
    }
}

pipeline {
	agent any
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
		/*stage('Test Package') {
			agent {
				dockerfile {}
			}
			steps {
				unstash 'deb-package'
			}
		}
		stage('Build Repository') {

		}*/
		stage('Test Repository') {
			agent any
			steps {
				script {
					def apt_repository = docker.build("apt-nginx", "-f ./apt-repository/nginx/Dockerfile .")
					def debian_buster_client = docker.build("debian-client", "-f ./docker/Dockerfile.debian-buster .")
					withDockerNetwork{ n ->
						apt_repository.withRun("--network ${n} --name apt-repository") { c ->
							debian_buster_client.inside("""
								--network ${n}
							""") {
								sh "wget http://apt-repository"
							}
						}
					}
				}
			}
		}
	}

    post {
        always {
            sh "chmod -R 777 ." // ensure Jenkins agent can delete the working directory
            deleteDir()
        }
    }
}
