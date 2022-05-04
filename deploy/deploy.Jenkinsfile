#!groovy
@Library('ot-orbit')

def jiraUtils = new com.onetrust.ci.utils.Jira()

node('master') {
     def branchName = URLDecoder.decode(env.BRANCH_NAME, "UTF-8")
     def scmVars = null
     def jsonFiles = []
     def artifactId = 'mobnativesdkflutter'
    try {
      waitForInProgressBuilds()

      stage('Init') {
        scmVars = init()
      }

      if (env.BRANCH_NAME.startsWith("PR-") || env.BRANCH_NAME == "development") {
        stage("Sonar Scan") {
          echo "Generating sonar project properties file from com/onetrust/ci/sonar-project.properties"
          def sonarProjectProperties = libraryResource 'com/onetrust/ci/sonar-project.properties'
          writeFile file: "sonar-project.properties", text: sonarProjectProperties
          sh "printf '\n sonar.projectName=publishers-mobile-native-sdk-flutter' >> sonar-project.properties"
          sh "printf '\n sonar.projectKey=publishers-mobile-native-sdk-flutter:Flutter-Native-SDK' >> sonar-project.properties"
          sh "printf '\n sonar.sourceEncoding=UTF-8' >> sonar-project.properties"
          sh "printf '\n sonar.sources=android, ios' >> sonar-project.properties"
          sh "printf '\n sonar.exclusions=**/*.java' >> sonar-project.properties"
          sh "printf '\n sonar.c.file.suffixes=-' >> sonar-project.properties"
          sh "printf '\n sonar.cpp.file.suffixes=-' >> sonar-project.properties"
          sh "printf '\n sonar.objc.file.suffixes=-' >> sonar-project.properties"
          withCredentials([string(credentialsId: 'sonarqube-analysis-snapshot-token', variable: 'sonarApiKey')]) {
            sh "printf '\n sonar.login=${sonarApiKey}' >> sonar-project.properties"
            if (env.BRANCH_NAME.startsWith("PR-")) {
              sh "printf '\n sonar.pullrequest.key=${env.CHANGE_ID}' >> sonar-project.properties"
              sh "printf '\n sonar.pullrequest.branch=${env.CHANGE_BRANCH}' >> sonar-project.properties"
              sh "printf '\n sonar.pullrequest.base=${env.CHANGE_TARGET}' >> sonar-project.properties"
            }
          }
          withCredentials([[ $class: 'UsernamePasswordMultiBinding', credentialsId: 'docker-deployer', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
            sh "docker login docker.onetrust.dev -u $USERNAME -p $PASSWORD && docker pull docker.onetrust.dev/frontend-sonar-openjdk11:0.1.5"
          }
          withSonarQubeEnv {
            sh "docker run --rm --user `id -u`:`id -g` -v ${WORKSPACE}:/usr/src docker.onetrust.dev/frontend-sonar-openjdk11:0.1.5"
          }
          sleep(5)
          timeout(time: 15, unit: 'MINUTES') {
            def qg = waitForQualityGate()
            if (qg.status != 'OK') {
              error "Pipeline aborted due to quality gate failure: ${qg.status}"
            }
          }
        }
      }

      stage('Package') {
        packageArtifacts(artifactId, branchName)
      }

      stage('Validate file(s)') {
        jsonFiles = getChangedJsonFiles(scmVars)
        echo "Json files are ${jsonFiles}"
        if (jsonFiles.size() == 0) {
            echo "No new changes to Json files : ${jsonFiles}"
            return
        }
        validateJson(jsonFiles)
      }

      if (branchName == 'development' && jsonFiles.size() > 0) {
      def emailList = "hhassan@onetrust.com,"
        for (jsonFile in jsonFiles) {
          def emails = sh (returnStdout: true, script: "cat '${jsonFile}' | jq -r '.email_list' ").trim()
          emailList += "${emails},"
        }
        validateEmailList(emailList)
        stage('Run Publish') {
          runPublish(emailList)
        }
      }
    } catch (Exception err) {
      if (branchName == 'development') {
        def emailList = "dl.devops@onetrust.com,"
        for (jsonFile in jsonFiles) {
          def emails = sh (returnStdout: true, script: "cat '${jsonFile}' | jq -r '.email_list' ").trim()
          emailList += "${emails},"
        }
        sendEmail("${emailList}", 'Npm publish Failed - publishers-mobile-native-sdk-flutter')
      }
      throw err
    }
}

def waitForInProgressBuilds() {
  def jenkinsUtils = new com.onetrust.ci.utils.Jenkins()
  def count = 0
  def MAX_TRIES = 360  // 1 hour timeout
  while(jenkinsUtils.previousBuildInProgress() && count < MAX_TRIES) {
    echo "Waiting for current in progress builds to complete..."
    sh "sleep 10 "
    count++
  }
  if (count >= MAX_TRIES) {
    error("Build reached the max timeout waiting on a previous build. Please verify that there are no 'In Progress' builds that are stuck.")
  }
}

def init() {
  deleteDir()
  echo 'Checking out Source Code'
  scmVars = checkout(scm)
  checkout([$class: 'GitSCM', branches: [[name: 'development']],
    extensions: [[$class: 'PruneStaleBranch'], [$class: 'RelativeTargetDirectory', relativeTargetDir: "publishers-mobile-native-sdk-flutter"]],
    userRemoteConfigs: [[url: "https://nexus.onetrust.com/git/scm/sdk/publishers-mobile-native-sdk-flutter.git", credentialsId: 'cibuild']]])
  echo 'Check out Completed for Source Code'
  return scmVars
}

def packageArtifacts(def artifactId, def branchName) {
  def branch = branchName.tokenize('/')
  echo "Package Artifacts Start"
  if ((branchName.startsWith("rc/") && branch.size() >= 2) || branchName == 'development' || branchName.startsWith('dev/')) {
      def version = 'latest'
      if (branchName != 'development') {
        version = branch[1]
      }
      echo "Branch is ${branchName}"
      withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'docker-deployer',
                      usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
          sh 'docker login nexus.onetrust.com:8443 -u $USERNAME -p $PASSWORD'
          sh "docker build -t nexus.onetrust.com:8443/${artifactId}:${version} --pull ."
          sh "docker push nexus.onetrust.com:8443/${artifactId}:${version}"
          sh "docker rmi nexus.onetrust.com:8443/${artifactId}:${version}"
          sh 'docker logout'
      }
  }
  echo "Package Artifacts Start"
}

def getChangedJsonFiles(def scmVars) {
  def changedFiles = []
  def changedJsonFiles =[]
  def jenkinsUtils = new com.onetrust.ci.utils.Jenkins()
  if (scmVars.GIT_PREVIOUS_COMMIT != null && env.BRANCH_NAME == 'development') {
    def previousCommit = jenkinsUtils.getPreviousBuildCommit(scmVars.GIT_PREVIOUS_COMMIT)
    changedFiles = sh(script: "git diff --name-only ${previousCommit} ${scmVars.GIT_COMMIT} | awk '{print \$1}'", returnStdout: true).trim().tokenize('\n')
  } else {
    changedFiles = sh(script: "git diff --name-only remotes/origin/development -- | awk '{print \$1}'", returnStdout: true).trim().tokenize('\n')
  }
  for (file in changedFiles) {
      if ("${file}".endsWith('deploy.json') && fileExists("${file}") && file.tokenize('/').last() != '_example.json' && "${file}".startsWith('deploy')) {
        echo "Json file ${file} has detected changes"
        changedJsonFiles.add(file)
      } else if (!fileExists("${file}")) {
        echo "${file} has detected changes but file does not exist!"
      } else {
        echo "${file} has detected changes"
      }
  }
  return changedJsonFiles
}

def validateJson(def jsonFiles) {

  def package_version = sh (returnStdout: true, script: " yq eval .version pubspec.yaml ").trim()
  echo "package_version = ${package_version}"

  for (jsonFile in jsonFiles) {
    sh "cat '${jsonFile}' | jq ."
      def version = sh (returnStdout: true, script: "cat '${jsonFile}' | jq -r '.version' ").trim()
      echo "version = ${version}"
      def pattern_version = "## " + version
      echo "pattern_version = ${pattern_version}"
      def changelog_version = sh (returnStdout: true, script: "cat CHANGELOG.md | grep '${pattern_version}'  ").trim()
      echo "changelog_version = ${changelog_version}"
      echo "Validating versions..."
      if (!version.equals(package_version)) {
        error("${version} is not in the valid package versions list:\n${package_version}")
      }
       if (!pattern_version.equals(changelog_version)) {
        error("${changelog_version} is not in the valid CHANGELOG versions list:\n${pattern_version}")
      }
  }
}

def validateEmailList(def emailList) {
  echo "Validating email addresses..."
  for (email in emailList.tokenize(',')) {
    if (!email.endsWith('@onetrust.com')) {
      error("${email} is not a valid OneTrust email address.")
    }
  }
}

def runPublish(emailList) {
  try {
    echo "Start runPublish"
    def jiraId = sh (returnStdout: true, script: "cat deploy/deploy.json | jq -r '.jira' ").trim()
    def deploy_to_prod = sh (returnStdout: true, script: "cat deploy/deploy.json | jq -r '.deploy_to_prod' ").trim()
    if (deploy_to_prod != "y" && deploy_to_prod != "Y"){
        echo "deploy_to_prod is not set to y/Y. Do not publish to Prod"
        return "empty"
    }
    def dry_run = sh (returnStdout: true, script: "cat deploy/deploy.json | jq -r '.dry_run' ").trim()
     def artifact_version = 'latest'
     def outputDir = '/opt/ot/app/logs/mobnativesdkflutter'
     def vmName = 'lkgb-app-vm0-eastus.qa.otdev.org'
     withCredentials([usernamePassword(credentialsId: 'docker-deployer', usernameVariable: 'dockerUser', passwordVariable: 'dockerPassword')]) {
     withCredentials([usernamePassword(credentialsId: 'mob-flutter-access-token', usernameVariable: 'PUB_DEV_PUBLISH_ACCESS_TOKEN', passwordVariable: 'accessToken')]) {
     withCredentials([usernamePassword(credentialsId: 'mob-flutter-refresh-token', usernameVariable: 'PUB_DEV_PUBLISH_REFRESH_TOKEN', passwordVariable: 'refreshToken')]) {
     withCredentials([usernamePassword(credentialsId: 'mob-flutter-token-endpoint', usernameVariable: 'PUB_DEV_PUBLISH_TOKEN_ENDPOINT', passwordVariable: 'tokenEndpoint')]) {
     withCredentials([usernamePassword(credentialsId: 'mob-flutter-id-token', usernameVariable: 'PUB_DEV_PUBLISH_ID_TOKEN', passwordVariable: 'idToken')]) {
     withCredentials([usernamePassword(credentialsId: 'mob-flutter-expiration', usernameVariable: 'PUB_DEV_PUBLISH_EXPIRATION', passwordVariable: 'expiration')]) {
        sh ("ssh -o StrictHostKeyChecking=no lkgb-app-vm0-eastus.qa.otdev.org 'bash -s ' < ./run-mobnativesdkflutter.sh  \\\"${dockerUser}\\\"  \\\"${dockerPassword}\\\" \\\"${artifact_version}\\\" \\\"${outputDir}\\\" \\\"${accessToken}\\\" \\\"${refreshToken}\\\" \\\"${tokenEndpoint}\\\" \\\"${idToken}\\\" \\\"${expiration}\\\" \\\"${dry_run}\\\" ")
     }
     }
     }
     }
     }
     }
    def version = sh (returnStdout: true, script: "cat deploy/deploy.json | jq -r .version ").trim()
    def comment = "dart publish dry_run=${dry_run} completed successfully for the request - version = ${version} - publishers-mobile-native-sdk-flutter"
    def response = sendResultsToJira(jiraId, comment )
    sendEmail("${emailList}", "Success:  ${comment}")
    echo "End runPublish"

  } catch (err) {
    sendEmail("${emailList}", 'Npm publish Failed - publishers-mobile-native-sdk-flutter')
    error(err.getMessage())
  }
}

def sendResultsToJira(def jiraId, def comment) {
  def jiraUtils = new com.onetrust.ci.utils.Jira()
  def response = jiraUtils.addComment(jiraId, comment)
}

def sendEmail(def mailTo, def subject) {
  if ("${mailTo}" != '') {
    emailext(attachLog: true,
      body: "${BUILD_URL}", mimeType: 'text/html',
      replyTo: 'noreply@onetrust.com', subject: "${subject}",
      to: "${mailTo}")
  } else {
    echo "Email list is empty."
  }
}

def log(def comments) {
    echo "${comments}"
    sh (returnStdout: true, script: "echo '${comments}' >> ${logFile}")
}

