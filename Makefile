ISTIO_VERSION="1.18.0-alpha.0"


clean:
	kind delete clusters ambient
	rm -rf ./istio-${ISTIO_VERSION}

kind:
	kind create cluster --config samples/kind-config.yaml

gatewayapi:
	kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v0.6.1" | kubectl apply -f -

get_istioctl:
	echo "installing istio into current working dir"
	echo
	echo
	curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} TARGET_ARCH=x86_64 sh -

install_ambient:
	./istio-${ISTIO_VERSION}/bin/istioctl install --set profile=ambient --skip-confirmation

deploy_sample_services:
	kubectl apply -f ./istio-${ISTIO_VERSION}/samples/bookinfo/platform/kube/bookinfo.yaml
	kubectl apply -f ./istio-${ISTIO_VERSION}/samples/sleep/sleep.yaml
	kubectl apply -f ./istio-${ISTIO_VERSION}/samples/sleep/notsleep.yaml

label_ambient:
	kubectl label namespace default istio.io/dataplane-mode=ambient

deploy_ns_waypoint:
	./istio-${ISTIO_VERSION}/bin/istioctl x waypoint apply

deploy_sa_waypoint:
	./istio-${ISTIO_VERSION}/bin/istioctl x waypoint apply --service-account bookinfo-productpage

configure_l4_authz_policy:
	kubectl apply -f samples/l4-authz-policy.yaml

post_sleep:
	kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"

post_notsleep:
	kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"

ready: clean get_istioctl kind gatewayapi install_ambient install_ambient deploy_sample_services label_ambient
