apiVersion: apps/v1
kind: Deployment
metadata:
  name: aspnetapp
  namespace: aspnetapp-staging

  labels:
    app.kubernetes.io/name: aspnetapp
    app.kubernetes.io/part-of: dotnet-aspnetapp
    app.kubernetes.io/managed-by: Jenkins

  annotations:
    kubernetes.io/change-cause: "__CHANGE_CAUSE__"

spec:
  replicas: 2

  revisionHistoryLimit: 5
  progressDeadlineSeconds: 300
  minReadySeconds: 5

  strategy:
    type: RollingUpdate

    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1

  selector:
    matchLabels:
      app.kubernetes.io/name: aspnetapp
      app.kubernetes.io/part-of: dotnet-aspnetapp

  template:
    metadata:
      labels:
        app.kubernetes.io/name: aspnetapp
        app.kubernetes.io/part-of: dotnet-aspnetapp
        app.kubernetes.io/version: "__SHORT_COMMIT__"

      annotations:
        ci.jenkins.io/build-number: "__BUILD_NUMBER__"
        ci.jenkins.io/git-commit: "__FULL_COMMIT__"

    spec:
      serviceAccountName: aspnetapp
      automountServiceAccountToken: false
      terminationGracePeriodSeconds: 30

      securityContext:
        runAsNonRoot: true
        runAsUser: 1654
        runAsGroup: 1654
        fsGroup: 1654
        fsGroupChangePolicy: OnRootMismatch

        seccompProfile:
          type: RuntimeDefault

      containers:
        - name: aspnetapp
          image: "__DEPLOY_IMAGE__"
          imagePullPolicy: IfNotPresent

          ports:
            - name: http
              containerPort: 8080
              protocol: TCP

          env:
            - name: ASPNETCORE_HTTP_PORTS
              value: "8080"

            - name: DOTNET_EnableDiagnostics
              value: "0"

          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            runAsUser: 1654
            runAsGroup: 1654

            capabilities:
              drop:
                - ALL

          resources:
            requests:
              cpu: 100m
              memory: 128Mi

            limits:
              cpu: 500m
              memory: 512Mi

          startupProbe:
            httpGet:
              path: /healthz
              port: http

            periodSeconds: 2
            timeoutSeconds: 1
            failureThreshold: 30

          readinessProbe:
            httpGet:
              path: /healthz
              port: http

            periodSeconds: 5
            timeoutSeconds: 2
            successThreshold: 1
            failureThreshold: 3

          livenessProbe:
            httpGet:
              path: /healthz
              port: http

            periodSeconds: 10
            timeoutSeconds: 2
            failureThreshold: 3

          volumeMounts:
            - name: data-protection
              mountPath: /home/app/.aspnet

            - name: temporary-files
              mountPath: /tmp

      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100

              podAffinityTerm:
                topologyKey: kubernetes.io/hostname

                labelSelector:
                  matchLabels:
                    app.kubernetes.io/name: aspnetapp
                    app.kubernetes.io/part-of: dotnet-aspnetapp

      volumes:
        - name: data-protection
          emptyDir: {}

        - name: temporary-files
          emptyDir: {}