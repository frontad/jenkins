#!groovy
import groovy.json.*

node() {
    stage("fetch code") {
        // code check out
	    checkout scm
        // get commit id
	    sh "git rev-parse --short HEAD > commit-id"
        sh "git rev-parse --short HEAD > branch"
        // commit commit-id as a variable
	    tag = readFile('commit-id').replace("\n", "").replace("\r", "")
	    brnc = readFile('branch').replace("\n", "").replace("\r", "")
	    env.TAG=tag
        env.UP_BUILD_NUMBER=tag
        env.BRNACH = brnc
	    appName = "web"
	    registryHost = "192.168.1.201:5000/dev/"
        def customImage = docker.build("songJenkins:${env.UP_BUILD_NUMBER}")
    }
}