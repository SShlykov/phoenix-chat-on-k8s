**Создаем deployment из закешированного образа**
Установим стратегию плавного обновления,
Возьмем только локальный контейнер (запрет на "пул"), ограничим ресурсы, укажем стандартный порт и опишем окружение и способ запуска. 
```yaml
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: chat
  namespace: default
spec:
  replicas: 4
  selector:
    matchLabels:
      app: chat
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 34%
      maxUnavailable: 34%
  template:
    metadata:
      labels:
        app: chat
    spec:
      containers:
      - name: phoenix-chat
        image: chat:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 4000
        resources:
          limits:
            memory: 1Gi
            cpu: "1"
          requests:
            memory: 512Mi
            cpu: ".2"
        env:
        - name: PORT
          value: "4000"
        - name: PHOENIX_CHAT_HOST
          value: "localhost.com"
        - name: MY_POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        command: ["elixir"]
        args: ["--name", "chat@$(MY_POD_IP)", "--cookie","secret", "--no-halt", "-S","mix","phx.server"]

```

**LoadBalancer**
Для балансировки нагрузки используем сервис, явно укажем порты и их трансляцию
```yaml
---
kind: Service
apiVersion: v1
metadata:
  name: chat
  namespace: default
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local
  selector:
    app: chat
  ports:
    - protocol: TCP
      port: 80
      targetPort: 4000
      nodePort: 32010
```


**Headless Service**
Для реализации связи между сервисами нам нужно будет использовать данный вид сервиса, канал связи, который будет отслеживать - epmd (Erlang Port Mapper Daemon) - средство. Программы на Эрланге используют для связи между собой нотацию node@host, физически же каждый узел (системный процесс) открывает для этого случайный высокий порт. Задача сервиса epmd — связать между собой логическую адресацию по имени и физическую адресацию по номеру порта.

```yaml
---
kind: Service
apiVersion: v1
metadata:
  name: chat-nodes
  namespace: default
spec:
  clusterIP: None
  selector:
    app: chat
  ports:
    - name: epmd
      port: 4369

```

**INGRESS**
Можно было бы на том и остановиться и обращаться к сервису балансировки, но в окружениях, которые поддерживают конфигурации сетевых ресурсов, управляемые через API, Kubernetes позволяет настроить всё, что нужно, в одном месте.
После выделения внешнего IP-адреса к сервису можно подключиться через этот адрес, назначить ему доменное имя и сообщить клиентам. До тех пор, пока сервис не будет уничтожен и создан повторно, IP-адрес меняться не будет. Но такой сервис нельзя настроить на расшифровку HTTPS-трафика. Нельзя создавать виртуальные хосты или настраивать маршрутизацию, основанную на путях, поэтому нельзя, строя конфигурации, применимые на практике, использовать единственный балансировщик нагрузки со множеством сервисов. 
***поэтому мы таки настроим ингрес для приема 2х типов путей по /ws и / (хотя сейчас они и будут одинаковыми)***

```yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: chat-ws
  namespace: default
spec:
  rules:
  - host: test.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service: 
            name: chat
            port: 
              number: 80
      - path: /ws
        pathType: Prefix
        backend:
          service: 
            name: chat
            port: 
              number: 80
```