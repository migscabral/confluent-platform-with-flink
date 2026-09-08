# CP and CP Flink on OCP POC YAML bundle

## POC licensing assumption

This POC does not require a license file, license Secret, or license command. It assumes the platform trial entitlement and expires after 30 days. Record the POC start date and calculate the expiry date before deployment. Obtain the appropriate license before extending the POC or using the deployment for production.

## CFK version variables

The CFK product/operator version and the Helm chart version are different:

- `CFK_VERSION=3.3.0` is the CFK product/operator version.
- `CFK_CHART_VERSION=0.1718.10` is the Helm chart version used with `helm upgrade --install --version`.
- `INIT_VERSION=3.3.0` is the Confluent init-container version used by the CP Custom Resources.

The Helm command validates the chart metadata before installation.

## Public image registry

This bundle uses the public Confluent repositories on Docker Hub:

- `docker.io/confluentinc/confluent-operator`
- `docker.io/confluentinc/confluent-init-container`
- `docker.io/confluentinc/cp-server`
- `docker.io/confluentinc/cp-server-connect`
- `docker.io/confluentinc/cp-schema-registry`
- `docker.io/confluentinc/cp-enterprise-control-center-next-gen`
- `docker.io/confluentinc/cp-flink`

Image pulls are anonymous. This bundle does not create, reference, or require an image-pull Secret. The OCP cluster must have outbound HTTPS access to Docker Hub and the Helm client must have access to `https://packages.confluent.io/helm`.

If the cluster cannot reach Docker Hub, stop the procedure and use the customer-approved internal registry/mirroring process instead; do not add credentials to this bundle.

## OpenShift security model

This bundle uses the OpenShift default SCC. Do not grant `privileged`, `anyuid`, or a custom SCC for this POC. Do not hard-code a UID, GID, or fsGroup because OpenShift assigns namespace-specific values.

The security settings are applied as follows:

- CFK Helm install uses `--set podSecurity.enabled=false`; this prevents CFK from forcing fixed operator-pod identities.
- Every CP CR that creates pods has `spec.podTemplate.podSecurityContext: {}`. OpenShift supplies the admitted identity.
- The FlinkApplication has the same empty pod security context under both JobManager and TaskManager pod templates.
- FKO uses `fko-ocp-values.yaml` with `runAsUser: null` and `runAsGroup: null`.
- CMF uses `cmf-ocp-values.yaml` with namespace-assigned UID/GID/fsGroup, `seccompProfile: RuntimeDefault`, `allowPrivilegeEscalation: false`, and all Linux capabilities dropped.
- CMFRestClass, FlinkEnvironment, Connector, and Secret resources do not create pods and therefore do not accept a pod security context. Their generated pods inherit the settings above.

Run these checks before deployment:

```bash
oc get scc restricted-v2 -o yaml
oc get ns operator confluent flink --show-labels
oc adm policy who-can use scc/restricted-v2
```

After installation, verify that the operator and workload pods were admitted with an OpenShift-assigned identity:

```bash
for ns in operator confluent flink; do
  oc get pods -n "$ns" -o custom-columns='NAME:.metadata.name,SA:.spec.serviceAccountName,UID:.spec.securityContext.runAsUser,GID:.spec.securityContext.runAsGroup,FSGroup:.spec.securityContext.fsGroup,NONROOT:.spec.securityContext.runAsNonRoot'
done
```

## TLS handling

TLS material is generated and approved outside OCP before this MOP starts. This bundle does not generate, convert, rotate, or inspect certificate SANs. Place the existing files on the MOP execution workstation and set their paths in `poc-parameters.env`. Run `load-existing-tls-secrets.sh` before deploying CP.

Do not run cert-manager or any certificate-generation command for this MOP.

## Deployment order

1. Apply `00-namespaces.yaml`.
2. Source `poc-parameters.env`; no image-pull Secret is created.
3. Run `load-existing-tls-secrets.sh`.
4. Check the default SCC and install FKO, CMF, and CFK in `operator`.
5. Apply `01-cp.yaml` in `confluent`.
6. Apply `02-flink.yaml` in `flink`.
7. Apply `03-connectors.yaml` in `confluent`.
8. Validate pod identities, Routes, connectors, and Flink status.

The bundle uses three namespaces: `operator` for CFK/CMF/FKO operators, `confluent` for CP resources and TLS/connector Secrets, and `flink` for Flink resources and generated JobManager/TaskManager pods.
