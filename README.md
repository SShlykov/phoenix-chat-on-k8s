# ChatLv
Часть кода взято с
https://github.com/poeticoding/phoenix_chat_example
(немного устарела версия)
# Этапы создания приложения
```mermaid
graph LR
  разработка --> нативный_кластер --> кластер_k8s
```
# Этап 1 разработка
**Напишем простейший канал для чата на стороне клиента**
Потребует установленный в системе - elixir, phoenix framework (для создания пустого приложения) 
Ожидаемый результат - 

![stage_1](./docs/stage1.png)
1. Создадим phx приложение без ОРМ ecto
    (без ОРМ) ```mix phx.new chat_lv --no-ecto```
    (с ОРМ) ```mix phx.new chat_lv```
2. Опишем шаблон для чата, сконфигурируем сервер и контроллер
    [посмотреть](./docs/prepare_app.md)
3. Напишем простейший канал для чата на стороне клиента
    [посмотреть](./docs/create_app_js.md)
4. Готово к запуску
   (Если создано с ОРМ нужно инициализировать базу данных, данные базы нужно внести в config/dev.exs)
   ```mix phx.server```

Когда узел Erlang запускается, узел имеет имя и получает адрес от ядра ОС хоста. Имя и адрес отправляются epmd демону, работающему на локальном хосте. В среде TCP / IP адрес состоит из IP-адреса и номера порта. Имя узла - это атом на форме Name@Node. Задача epmd демона - отслеживать, какое имя узла прослушивает какой адрес. Следовательно, epmd сопоставьте символьные имена узлов с машинными адресами
Демон запускается автоматически сценарием запуска Erlang.
Программа epmd также может использоваться для множества других целей, например, для проверки конфигурации DNS хоста и др.

Для нас это обозначает, что мы после небольшой настройки конфигов можем создать распределенную сети приложений 

**Нужно обновить конфигурацию, чтобы при запуске приложения задавать нужные параметры динамечески** 
```elixir
db_url          = System.get_env("DB_URL") || "ecto://postgres:postgres@localhost/chat_lv_dev"
port            = System.get_env("PORT") || 4000

#--> config/dev.exs
config :chat_lv, ChatLv.Repo,
  url: db_url,
  pool_size: 10

config :chat_lv, ChatLvWeb.Endpoint,
  http: [port: port],
  ...
```

# Объединение в кластер
Ожидаемый результат: оъединенные в кластер ноды, которые в будущем могли бы быть использованы балансировшиком - 
![stage_2](./docs/stage2.png)
**Через нативные ноды в разных консолях**
```bash
PORT=4000 iex --sname a@localhost -S mix phx.server
PORT=4001 iex --sname b@localhost -S mix phx.server
PORT=4002 iex --sname c@localhost -S mix phx.server
```
```elixir
#--> видим только текущий
Node.list([:this, :visible]) 
#--> затем в подключаемся к остальным
Node.connect(:b@localhost)
Node.connect(:c@localhost)
#--> затем можно рассмотреть все подключенные ноды включая текущую 
Node.list([:this, :visible]) 
#--> проверяем чаты по адресу 
#--> http://localhost:4000
#--> http://localhost:4001
#--> http://localhost:4002
```

**Рассмотрим простейшую стратегию объединения в кластер через libcluster (автоподключение)**
```elixir
#--> добавим зависимость libcluster в mix.exs
{:libcluster, "~> 3.2"}
#--> lib/chat_lv/application.ex 
#--> используем первую стратегию стратегию 
  topologies = [
    chat: [
      strategy: Cluster.Strategy.Gossip,
    ]
  ]
#--> создадим супервизор, следящий за нодами в children 
#--> lib/chat_lv/application.ex 
{Cluster.Supervisor, [topologies, [name: ChatLv.ClusterSupervisor]]},
```
***Теперь каждое новое созданное приложение будет подключаться и следить за нодами самостоятельно***
```bash
#--> проверяем
PORT=4000 iex --sname a@localhost -S mix phx.server
PORT=4001 iex --sname b@localhost -S mix phx.server
PORT=4002 iex --sname c@localhost -S mix phx.server
```


##K8s
![stage_1](./docs/stage3.png)
**Напишем prod конфииг**
```elixir
#--> config/prod.exs
db_url          = System.get_env("DB_URL") || "ecto://postgres:postgres@localhost/chat_lv_dev"
port            = System.get_env("PORT") || 4000
host            = System.get_env("PHOENIX_CHAT_HOST") || "localhost"
secret_key_base = System.get_env("SECRET_KEY_BASE") || "XR7e8rPXq2nIdBXqtPsyxPz1R1UF3w4HDBFGdxZ+9GDZCT6PpG4aJLpOzehOJVO5"

config :chat_lv, ChatLvWeb.Endpoint,
  http: [port: port],
  url:  [host: host],
  check_origin: false,
  transport_options: [socket_opts: [:inet6]],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: secret_key_base,
  server: true
config :chat_lv, ChatLv.Repo,
  url: db_url,
  pool_size: 10
```
**Напишем докер файл**

```dockerfile
#--> Dockerfile
FROM elixir:1.11-alpine

WORKDIR /app
ADD . /app
EXPOSE 4000
ENV PORT 4000 
ENV MIX_ENV prod

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix do deps.get, deps.compile && \
    mix do compile, phx.digest

CMD ["mix", "phx.server"]
```

**Запустим 2 окна в докере, и проверим работу** 

```bash
docker build -t chat:latest .
docker run --rm --name chat -p 4000:4000 -e PORT=4000 -it chat:latest sh
#--> Запустим в различных окнах и пообщаемся (проверим, что работает)
```

**Изменим стратегию соездинения приложений, теперь они будут общаться через DNS куба**

```elixir
#--> поправим стратегию lib/chat_lv/application.ex
#--> в конфиге service - сервис, который связывается 
#--> в конфиге application_name - имя сервиса 
topologies = [
   k8s_chat: [
     strategy: Cluster.Strategy.Kubernetes.DNS,
     config: [
       service: "chat-nodes",
       application_name: "chat"
     ]
   ]
]
#--> это необходимо для определения пространства имен сервисов
```

**Запустим миникуб**
```bash
#--> Круто для обучения и тестов. Создается докерфайл, ограниченный в ресурсах (CPUs=2, Memory=3900MB), легко запустить и убить
#--> Для вебсокет канала нужен ингресс
minikube start
minikube addons enable ingress
#--> Нужно проверить кэш и если что убить старые версии
#--> minikube cache list all
#--> minikube cache delete chat:latest
```

**Проверим образ и закешируем его**
```bash
#--> должен быть образ chat latest
#--> docker images
minikube cache add chat:latest
#--> minikube cache list all
```

**Напишем конфигурацию нашего приложения**
[база данных](./docs/database.md)
[приложение](./docs/k8s.md)
Внимание для Ingress указывается адрес его развертывания, временно, через хосты мы настроем его прием


**Запустим куб**
```bash
kubectl create -f database.yaml
kubectl create -f k8s.yaml
#--> посмотрим, как поднимается наш кластер
minikube dashboard
#--> после того, как мы увидели, что все запустилось
#--> (откроем в браузере)
#--> посмотрим еще и на namespaces
#--> в другой консоли 
#--> необходимо установить dnsutils (sudo apt install dnsutils)
nslookup chat-nodes
#--> посмотрим на ingress (он запускается не сразу)
kubectl get ingress -n default
#--> запишем адреса в /etc/hosts
sudo vim /etc/hosts
#--> i чтобы войти в инсерт мод
#--> прописываем записанный выше адрес
#--> escape + :wq
#--> ждем небольшое количество времени, переходим по адресу и запускаем в браузерах, видим, что мы находимся в разных нодах
#--> http://test.com
```

**Скейлим наш деплоймент**
```bash
#--> Предпочтительно изменить конфиг (добавить реплик до 10) и сделать apply
kubectl apply -f k8s.yaml
#--> kubectl scale --replicas=8 {{deployment}} 
#--> kubectl get pods
#--> kubectl exec -it {{pod}} sh
#--> iex -S mix
#--> 
```