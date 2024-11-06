## CDW Managed Services Kyverno Policies
These Kyverno policies are targeted for deployment to CDW Managed Services
Kubernetes clusters.  The intent is to use GitOps with
[kustomize](https://kustomize.io/) to install.

### How things are organized
Kustomize provides a solution for customizing Kubernetes resource configuration
free from templates and DSLs. It lets you customize raw, template-free YAML files
for multiple purposes, leaving the original YAML untouched and usable as is.

With this in mind, the simplest approach to understanding "how things work" is
to treat `kustomization.yaml` files as bread crumbs. That is to say, where you
find a `kustomization.yaml` file, it will take you to your next
`kustomization.yaml`...which in turn will take you to another
`kustomization.yaml`...etc., etc.

A common practice is to use `overlays` directories to model your different
environments (i.e. kubernetes clusters).  Following this pattern, our various
kubernetes clusters will have policy defined under overlays directories.

### Quick-and-dirty test
To see kustomize in action, just find a directory with a `kustomization.yaml`
file. To render Kubernetes manifests with kustomize, you execute a build
command against that directory, like so:

```sh
bash-5.0$ kustomize build overlays/eval
````

Or, if you want to render policy for local testing:

```sh
bash-5.0$ rm -rf "$HOME/code/rendered-kyverno-policy/stage"
bash-5.0$ mkdir "$HOME/code/rendered-kyverno-policy/stage"
bash-5.0$ kustomize build overlays/stage/ > "$HOME/code/rendered-kyverno-policy/stage/policy.yaml"
bash-5.0$
bash-5.0$ kyverno apply "$HOME/code/rendered-kyverno-policy/stage/policy.yaml" --resource deploy/deployment.yml
````
