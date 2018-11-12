# Buildkite Helm Charts Repository

The official [Buildkite](https://buildkite.com/docs/agent) [Helm](https://helm.sh) Charts repository.

## Getting Started

### Install Helm

Get the latest [Helm release](https://github.com/kubernetes/helm#install).

### Add Buildkite Helm chart repository:

 ```console
 $ helm repo add buildkite https://buildkite.github.io/charts/
 $ helm repo update
 ```

### Install chart

To install the Agent chart with the release name `bk-agent`:

```console
$ helm install --name bk-agent --namespace buildkite buildkite/agent --set agent.token="BUILDKITE_AGENT_TOKEN"
```

Check Agent chart [readme](stable/agent/README.md) for more customisation options.

** You’ve now got Buildkite Agents running on your Kubernetes cluster! :tada: **

## Contributing to Buildkite Charts

Fork the `repo`, make changes and test it by installing the chart to see it is working. :)

On success make a [pull request](https://help.github.com/articles/using-pull-requests) (PR).

Upon successful review, someone will give the PR a __LGTM__ in the review thread.

## Thanks :heart:

* A massive thanks to [Rimas Mocevicius](https://github.com/rimusz) for authoring this chart

## Copyright

Copyright (c) 2018 Buildkite Pty Ltd. See [LICENSE](LICENSE) for details.
