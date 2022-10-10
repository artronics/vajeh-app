const shell = require('shelljs')

const deployImage = "artronics/pipeline:latest"

function readAwsCred() {
  const aws_access_key_id = process.env.AWS_ACCESS_KEY_ID
  const aws_secret_access_key = process.env.AWS_SECRET_ACCESS_KEY
  if (!(aws_secret_access_key && aws_access_key_id)) {
    throw new Error('AWS credentials are not set. Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY')
  }

  return { aws_access_key_id, aws_secret_access_key }
}

function projectRootDir() {
  return __dirname
}

function terraformCmd(operation, tfVars = '') {
  const awsCred = readAwsCred()
  let extraOpt = ''
  if (operation === 'apply' || operation === 'destroy') {
    extraOpt += '-auto-approve'
  }
  const env = `-e AWS_ACCESS_KEY_ID=${awsCred.aws_access_key_id} -e AWS_SECRET_ACCESS_KEY=${awsCred.aws_secret_access_key}`
  const vol = `-v ${projectRootDir()}:/project`

  return `docker run --rm ${env} ${vol} ${deployImage} terraform -chdir=/project/terraform ${operation} ${extraOpt} ${tfVars}`
}

function makeEnv(env) {
  if (!env) {
    throw new Error('Deployment environment is not set')
  }
  return `-var=environment=${env}`
}

module.exports = function (grunt) {
  grunt.registerTask('terraform', 'terraform command', (command) => {
    if (command === 'init') {
      grunt.log.write(terraformCmd(command))
      shell.exec(terraformCmd(command))

    } else if (command === 'apply' || command === 'destroy' || command === 'plan') {
      const tfVars = makeEnv('dev')
      shell.exec(terraformCmd(command, tfVars))

    } else {
      grunt.fail.fatal(`terraform "${command}" command doesn't exist or not supported`)
    }
  })

  grunt.registerTask('build', 'build project', () => {
    shell.exec("yarn run build")
  })
}
