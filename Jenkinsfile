node {
    checkout scm
    def aptNginx = docker.build("apt-nginx", "./apt-repository/nginx") 

    aptNginx.inside {
        sh 'nginx -v'
    }
}