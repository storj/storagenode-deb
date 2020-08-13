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
			}
		}
	}
}
