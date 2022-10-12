const shell = require('shelljs')

const terraformImage = 'hashicorp/terraform:latest'

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

  return `docker run --rm ${env} ${vol} ${terraformImage} -chdir=/project/terraform ${operation} ${extraOpt} ${tfVars}`
}

function isGitHubAction() {
  return !!process.env.GITHUB_JOB
}
function isBranchDeployment(ghContext) {
  return ghContext['ref_type'] && ghContext['ref_type'] === 'branch'
}

module.exports = function (grunt) {
  const getDeploymentEnv = () => {
    if (isGitHubAction()) {
      const ctx = grunt.option('github-context')
      if (!ctx) {
        grunt.fail.fatal('--github-context option is required. Pass the GITHUB object as json')
      }
      grunt.log.write('context branch', ctx['ref_type'])
      grunt.log.write(ctx)
      if (isBranchDeployment(ctx)) {
        const prNo = grunt.option('pr-no')
        if (!prNo) {
          grunt.fail.fatal('--pr-no option is required. It\'s the GitHub Pull Request number.')
        }
        grunt.log.write('pr no is: ', prNo)
      }

      return 'dev'

    } else {
      const env = grunt.option('deployment-env')
      if (!env) {
        grunt.fail.fatal('--deployment-env option is required. For local deployment it must be in a short username format')
      }
      return env.toLowerCase().trim()
    }
  }

  const getWorkspace = () => {
    const { stdout } = shell.exec(terraformCmd(`workspace show`), {silent: true})
    return stdout.trim()
  }

  grunt.registerTask('terraform', 'terraform command', (command) => {
    if (command === 'init') {
      grunt.log.write(terraformCmd(command))
      shell.exec(terraformCmd(command))

    } else if (command === 'apply' || command === 'destroy' || command === 'plan') {
      const env = getDeploymentEnv()
      const ws = getWorkspace()
      if (ws !== env) {
        grunt.fail.fatal(`wrong workspace is selected. First switch to the right workspace: grunt workspace:select --deployment-env=${env}`)
      }

      shell.exec(terraformCmd(command))

    } else {
      grunt.fail.fatal(`terraform "${command}" command doesn't exist or not supported`)
    }
  })

  grunt.registerTask('workspace', 'create and list terraform workspace', (operation) => {
    const env = getDeploymentEnv()
    if (operation === 'new') {
      shell.exec(terraformCmd(`workspace new ${env}`))

    } else if (operation === 'select') {
      const ws = getWorkspace()
      if (ws === env) {
        grunt.log.warn(`workspace: ${env} is already selected`)
      } else {
        shell.exec(terraformCmd(`workspace select ${env}`))
      }
    } else {
      grunt.log.error(`operation ${operation} is either wrong or not supported`)
    }
  })

  grunt.registerTask('test', 'test pipeline', () => {
    shell.exec(terraformCmd('init'))
  })

  grunt.registerTask('foo', 'for testing locally', () => {
    getDeploymentEnv()
    shell.exec('ls')
  })

  grunt.registerTask('build', 'build project', () => {
    shell.exec('yarn run build')
  })
}
