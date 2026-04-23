# Spring Boot Hello World on Kubernetes via Argo CD

This sample shows a minimal Spring Boot application that can be:

1. built with Maven
2. containerized with Docker
3. deployed to Kubernetes
4. synced by Argo CD from Git instead of Jenkins

## App endpoints

- `/` returns a JSON hello message
- `/hello` returns `Hello World`
- `/actuator/health/liveness`
- `/actuator/health/readiness`

## Run locally

```bash
mvn spring-boot:run
```

Open:

```text
http://localhost:8080/hello
```

## Build the jar

```bash
mvn clean package
```

## Build and push the image

Update the image in [k8s/deployment.yaml](C:/dev/spring-boot-hello-k8s/k8s/deployment.yaml:17) first.

```bash
docker build -t docker.io/your-dockerhub-user/spring-boot-hello-k8s:latest .
docker push docker.io/your-dockerhub-user/spring-boot-hello-k8s:latest
```

The Dockerfile is a multi-stage build, so `docker build` can compile the jar for you even if `target/` is empty.

## Push the image the same way scanner images are pushed

The scanner repos in your workspace typically:

1. build a local image
2. tag it for `registry.strln.net`
3. push to `registry.strln.net`
4. log in to AWS ECR
5. retag and push to ECR

This sample includes the same style of flow in [scripts/build_and_push_image.sh](C:/dev/spring-boot-hello-k8s/scripts/build_and_push_image.sh:1).

Example:

```bash
chmod +x scripts/build_and_push_image.sh
./scripts/build_and_push_image.sh master-20260422-demo
```

Defaults used by the script:

- Quadra registry: `registry.strln.net/ares/spring-boot-hello-k8s:<tag>`
- ECR registry: `776389595347.dkr.ecr.us-west-2.amazonaws.com/ares/spring-boot-hello-k8s:<tag>`

You can override them:

```bash
PROJECT=ares \
IMAGE=spring-boot-hello-k8s \
AWS_ACCOUNT_ID=776389595347 \
AWS_PROFILE_NAME=ares-stage \
AWS_REGION_NAME=us-west-2 \
./scripts/build_and_push_image.sh master-20260422-demo
```

If your `registry.strln.net` token is expired or you only want to push to ECR:

```bash
SKIP_QUADRA_PUSH=true ./scripts/build_and_push_image.sh master-20260422-demo
```

## Deploy manually to Kubernetes

If your image is hosted in AWS ECR, create the image pull secret first:

```bash
TOKEN=$(aws --profile ares-stage ecr get-login-password --region us-west-2)

kubectl delete secret ecr-regcred -n hello-demo --ignore-not-found

kubectl create secret docker-registry ecr-regcred \
  --docker-server=776389595347.dkr.ecr.us-west-2.amazonaws.com \
  --docker-username=AWS \
  --docker-password="$TOKEN" \
  -n hello-demo
```

```bash
kubectl apply -k k8s
kubectl get pods -n hello-demo
kubectl get svc -n hello-demo
```

## Deploy with Argo CD

1. Push this repo to GitHub or your Git server.
2. Update `repoURL` in [argocd/application.yaml](C:/dev/spring-boot-hello-k8s/argocd/application.yaml:8).
3. Apply the Argo CD application:

```bash
kubectl apply -f argocd/application.yaml
```

4. Verify:

```bash
kubectl get applications -n argocd
kubectl get pods -n hello-demo
```

The deployment manifest uses `imagePullSecrets`:

- [k8s/deployment.yaml](C:/dev/spring-boot-hello-k8s/k8s/deployment.yaml:1)
- secret name: `ecr-regcred`

## Notes

- Argo CD watches Git and syncs the `k8s/` folder.
- For real projects, use versioned image tags instead of `latest`.
- If you want external access, add an Ingress or NodePort/LoadBalancer service.
# Hello-World-Example
