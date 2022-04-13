pipeline {
    agent any
    
    tools {
        terraform 'terraform'
    }
    stages {
  //   test   stage ("checkout from GIT") {hsbxhsswxwwxw
       //     steps {
          //      git branch: 'main', credentialsId: 'cde06f21-9ae7-4081-a549-f7bdb515dc6f', url: 'https://github.com/codepipe/tff.git'
        //    }
    //    }
        stage ("terraform init Prod ") {
            when {expression {GIT_BRANCH == 'origin/master'}} 
            steps {
                     dir('prod'){
                       sh 'terraform init -reconfigure'
                     }
                }
        }
        stage ("terraform init Stag ") {
            when {expression {GIT_BRANCH == 'origin/stag'}} 
            steps {
                         dir('staging'){
                           sh ("ls")
                           sh 'terraform init -reconfigure'
                        }
                       }
                    
                 }               
        stage ("terraform fmt Prod") {
            when {expression {GIT_BRANCH == 'origin/master'}}
            steps {
                dir('prod'){
                sh 'terraform fmt'
           
             } 
             }
        }
        stage ("terraform fmt Stag") {
            when {expression {GIT_BRANCH == 'origin/stag'}}
            steps {
                dir('prod'){
                sh 'terraform fmt'
           
             } 
             }
        }

        stage ("terraform validate Prod") {
            when {expression {GIT_BRANCH == 'origin/master'}}
            steps {
                dir('prod'){
                sh 'terraform validate'
            }
            }

        }
         stage ("terraform validate Stag") {
            when {expression {GIT_BRANCH == 'origin/stag'}}
            steps {
                dir('staging'){
                sh 'terraform validate'
            }
            }

        }
        stage ("terrafrom plan Prod") {
            when {expression {GIT_BRANCH == 'origin/master'}}
            steps {
                dir('prod'){
                sh 'terraform plan'
            }
            }
        }
        stage ("terrafrom plan Stag") {
            when {expression {GIT_BRANCH == 'origin/stag'}}
            steps {
                dir('staging'){
                sh 'terraform plan'
            }
            }
        }
        stage ("terraform apply Stag") {
            when {expression {GIT_BRANCH == 'origin/stag'}}
             input{
                message "Do you want to proceed for stag deployment?"
              }
            steps {
                dir('staging'){
                sh 'terraform apply --auto-approve'
            }
            }
        }
        stage ("terraform apply prod") {
            when {expression {GIT_BRANCH == 'origin/master'}}
             input{
              message "Do you want to proceed for prod deployment?"
              }
            steps {
                dir('prod'){
                sh 'terraform apply '
            }
            }
        }
   //             sh   ddtest'terraform apply --auto-approve'
  //          }
  //      }


      }
 }