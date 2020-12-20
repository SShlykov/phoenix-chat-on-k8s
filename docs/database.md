**PVC**
Если вы подумаете о том, что такое кластер k8s, то это, по сути, набор физических машин, каждая из которых имеет собственное внутреннее хранилище, а также сетевое подключение к общему хранилищу, обычно такое как SAN или что-то в этом роде. База данных нуждается в постоянном месте для размещения файлов, которые будут продолжать существовать независимо от того, что происходит с работающими контейнерами или узлами кластера k8s, и это то, что вам дает утверждение постоянного тома (PVC). 

```yaml
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: postgres-pvc
  labels:
    app: postgres
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

**Deployment**

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: postgresql
    spec:
      containers:
      - env:
        - name: POSTGRES_DB
          value: chat_lv_prod
        - name: POSTGRES_PASSWORD
          value: postgres
        image: postgres:latest
        name: db
        ports:
        - containerPort: 5432
        resources: {}
        volumeMounts:
        - mountPath: /var/lib/postgresql/data
          name: data
      hostname: db
      restartPolicy: Always
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: postgres-pvc
```


**Service**

```yaml
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: postgresql
  name: db
spec:
  ports:
  - name: postgres
    port: 5432
    targetPort: 5432
  selector:
    app: postgresql


```