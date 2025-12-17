# Quick Example: Dynamic Job Name

The simplest use case for template substitution is creating dynamic job names.

## Template File

```hcl
job "[[JOB_NAME]]" {
  datacenters = var.datacenters
  type        = "service"

  group "app" {
    count = var.count
    # ... rest of job config
  }
}
```

## Variables File

```hcl
datacenters = [[DATACENTERS]]
count       = [[COUNT]]
```

## GitHub Workflow

```yaml
- uses: dpfisterer/ssh-deploy-to-nomad@v1
  with:
    ssh-host: ${{ secrets.NOMAD_HOST }}
    ssh-user: ${{ secrets.NOMAD_USER }}
    ssh-key: ${{ secrets.SSH_PRIVATE_KEY }}
    service-name: my-api
    hcl-template: nomad/template.nomad.hcl
    hcl-variables: nomad/variables.vars.hcl
    action: run
    env-vars: |
      JOB_NAME: my-api-production
      DATACENTERS: ["dc1", "dc2"]
      COUNT: 3
```

## Result

The deployed Nomad job will be named `my-api-production` with 3 instances running in datacenters dc1 and dc2.

**Note:** You can use the same template for multiple environments by changing only `JOB_NAME`:
- `my-api-production`
- `my-api-staging`
- `my-api-dev`
