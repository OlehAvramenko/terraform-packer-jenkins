#!/bin/bash
set -x

function wait_for_jenkins ()
{
    echo " ------------------ Waiting jenkins to launch on 8080 -------------------- "

    while (( 1 )); do
        echo " ---------------- Waiting for Jenkins ---------------- "

        code=$(curl -I -s -L http://localhost:8080/login | grep "HTTP/1.1")
        result=$(echo $code | grep 200 > /dev/null && echo "200" || echo "FAIL")
        if (( $result == 200 )); then
            break
        fi

        sleep 10
    done

    echo " ------------------ Jenkins launched ---------------- "
}


function updating_jenkins_master_password ()
{
  cat > /tmp/jenkinsHash.py <<EOF
import bcrypt
import sys
if not sys.argv[1]:
  sys.exit(10)
plaintext_pwd=sys.argv[1]
encrypted_pwd=bcrypt.hashpw(sys.argv[1], bcrypt.gensalt(rounds=10, prefix=b"2a"))
isCorrect=bcrypt.checkpw(plaintext_pwd, encrypted_pwd)
if not isCorrect:
  sys.exit(20);
print "{}".format(encrypted_pwd)
EOF

  chmod +x /tmp/jenkinsHash.py

  # Wait till /var/lib/jenkins/users/admin* folder gets created
  sleep 10

  cd /var/lib/jenkins/users/admin*
  pwd
  while (( 1 )); do
      echo "--------- Waiting for Jenkins to generate admin user's config file ---------- "

      if [[ -f "./config.xml" ]]; then
          break
      fi

      sleep 10
  done

  echo " --------------- Admin config file created ------------------- "

  ADMIN_PASSWORD=$(python /tmp/jenkinsHash.py ${JENKINS_ADMIN_PASSWORD} 2>&1)

  # Please do not remove alter quote as it keeps the hash syntax intact or else while substitution, $<character> will be replaced by null
  xmlstarlet -q ed --inplace -u "/user/properties/hudson.security.HudsonPrivateSecurityRealm_-Details/passwordHash" -v '#jbcrypt:'"$ADMIN_PASSWORD" config.xml

  # Restart
  systemctl restart jenkins
  sleep 10
}

function install_packages ()
{

  wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
  sh -c 'echo deb https://pkg.jenkins.io/debian binary/ > \
      /etc/apt/sources.list.d/jenkins.list'
  apt -y  update
  apt -y install jenkins

  usermod -aG docker jenkins
  systemctl start docker
  chmod 666 /var/run/docker.sock
  chown root:docker /var/run/docker.sock

  systemctl enable jenkins
  systemctl restart jenkins
  sleep 10
}

function configure_jenkins_server ()
{
  # sleep 60
  JENKINS_DIR="/var/lib/jenkins"
  PLUGINS_DIR="$JENKINS_DIR/plugins"

  cd $JENKINS_DIR
  # Jenkins cli
  echo "installing the Jenkins cli ..."
  wget http://localhost:8080/jnlpJars/jenkins-cli.jar

  # Getting initial password
  # PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
  PASSWORD="${JENKINS_ADMIN_PASSWORD}"
  echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("user", "${JENKINS_USER_PASSWORD}")' |   \
  java -jar jenkins-cli.jar -auth admin:$PASSWORD -s http://localhost:8080/ groovy =

  # Open JNLP port
  xmlstarlet -q ed --inplace -u "/hudson/slaveAgentPort" -v ${SLAVE_PORT} config.xml

  cd $PLUGINS_DIR || { echo "unable to chdir to [$PLUGINS_DIR]"; exit 1; }

  #  --------------------- remove existing plugins, if any ------------------------
  rm -rfv $PLUGIN_LIST

  for PLUGIN in $PLUGIN_LIST; do
      echo "installing plugin [$PLUGIN] ..."
      java -jar $JENKINS_DIR/jenkins-cli.jar -s http://localhost:8080/ -auth admin:$PASSWORD install-plugin $PLUGIN
  done


  # ------------------ Restart jenkins after installing plugins ----------------------
  java -jar $JENKINS_DIR/jenkins-cli.jar -s http://localhost:8080 -auth admin:$PASSWORD safe-restart
}

function add_jobs ()
{
  # sleep 60
  cd $JENKINS_DIR
  # --------------------------- ADD add_jobs ------------------------
  git clone ${REPO} && cd manifest
  xmlstarlet -q ed --inplace -u "/com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl/password" -v ${GITLAB_TOKEN} deploy-token.xml
  java -jar $JENKINS_DIR/jenkins-cli.jar -auth admin:$PASSWORD -s http://localhost:8080/ create-credentials-by-xml system::system::jenkins _  < deploy-token.xml
  java -jar $JENKINS_DIR/jenkins-cli.jar -auth admin:$PASSWORD -s http://localhost:8080 create-job ${JOB_NAME} < spring-config.xml

  # ------------------- Add webhook in gitlab --------------------
  MASTER_IP=$(curl http://checkip.amazonaws.com)
  curl -k --request POST --header "PRIVATE-TOKEN:${GITLAB_TOKEN}" \
  https://gitlab.com/api/v4/projects/${PROJECT_ID}/hooks?url=http://$MASTER_IP:8080/project/${JOB_NAME}/ --data "token=${SECRET_TOKEN}"

  # --------------------- Add secret token in groovy envs for pipeline -----------------------------

  cat > /tmp/addenv.groovy <<EOF
  import hudson.EnvVars;
  import hudson.slaves.EnvironmentVariablesNodeProperty;
  import hudson.slaves.NodeProperty;
  import hudson.slaves.NodePropertyDescriptor;
  import hudson.util.DescribableList;
  import jenkins.model.Jenkins;
  public createGlobalEnvironmentVariables(String key, String value){

          Jenkins instance = Jenkins.getInstance();

          DescribableList<NodeProperty<?>, NodePropertyDescriptor> globalNodeProperties = instance.getGlobalNodeProperties();
          List<EnvironmentVariablesNodeProperty> envVarsNodePropertyList = globalNodeProperties.getAll(EnvironmentVariablesNodeProperty.class);

          EnvironmentVariablesNodeProperty newEnvVarsNodeProperty = null;
          EnvVars envVars = null;

          if ( envVarsNodePropertyList == null || envVarsNodePropertyList.size() == 0 ) {
              newEnvVarsNodeProperty = new hudson.slaves.EnvironmentVariablesNodeProperty();
              globalNodeProperties.add(newEnvVarsNodeProperty);
              envVars = newEnvVarsNodeProperty.getEnvVars();
          } else {
              envVars = envVarsNodePropertyList.get(0).getEnvVars();
          }
          envVars.put(key, value)
          instance.save()
  }
  createGlobalEnvironmentVariables('SECRET_TOKEN','${SECRET_TOKEN}')
EOF

java -jar $JENKINS_DIR/jenkins-cli.jar -auth admin:$PASSWORD -s http://localhost:8080/ groovy = < /tmp/addenv.groovy

}

# ------------------- List of plugins that are needed to be installed --------------------------
PLUGIN_LIST="git github ssh-slaves workflow-aggregator ws-cleanup gitlab-plugin"

### ------------- script starts here ---------------- ###

install_packages

wait_for_jenkins

updating_jenkins_master_password

wait_for_jenkins

configure_jenkins_server

wait_for_jenkins

add_jobs

chmod 400 /var/log/cloud-init-output.log
echo "======================== Done ========================="
exit 0
