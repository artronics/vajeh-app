import os
from dataclasses import dataclass

from invoke import task


@dataclass
class AwsCred:
    aws_access_key_id: str
    aws_secret_access_key: str


def read_aws_cred() -> AwsCred:
    key = os.getenv('AWS_ACCESS_KEY_ID')
    secret = os.getenv('AWS_SECRET_ACCESS_KEY')
    if not key or not secret:
        raise Exception("AWS credentials are not set. Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY")
    return AwsCred(aws_access_key_id=key, aws_secret_access_key=secret)


def project_root_dir() -> str:
    return os.path.dirname(os.path.realpath(__file__))


def terraform_cmd(op, tf_vars="") -> str:
    aws_cred = read_aws_cred()
    ext = ""
    if op == "apply" or op == "destroy":
        ext = "-auto-approve"
    env = f"-e AWS_ACCESS_KEY_ID={aws_cred.aws_access_key_id} -e AWS_SECRET_ACCESS_KEY={aws_cred.aws_secret_access_key}"
    vol = f"-v {project_root_dir()}:/app"
    ver = "latest"

    return f"docker run {env} {vol} hashicorp/terraform:{ver} -chdir=/app/terraform {op} {ext} {tf_vars}"


def make_env(env) -> str:
    if not env:
        raise Exception("Deployment environment is not set")
    return f"-var='environment={env}'"


@task
def terraform_init(c):
    c.run(terraform_cmd("init"))


@task
def terraform_apply(c, env=None):
    tf_vars = f"{make_env(env)}"
    cmd = terraform_cmd("apply", tf_vars)
    c.run(cmd)


@task
def terraform_destroy(c, env=None):
    tf_vars = f"{make_env(env)}'"
    cmd = terraform_cmd("destroy", tf_vars)
    c.run(cmd)


@task
def build(c):
    c.run("yarn run build")
