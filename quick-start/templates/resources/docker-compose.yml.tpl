version: "3"
services:

  gateway:
    image: nginx:latest
    container_name: gateway
    depends_on:
      - ui
    ports:
      - "80:80"
    volumes:
      - type: bind
        source: ./nginx.conf
        target: /etc/nginx/conf.d/default.conf
    restart: always
    platform: linux/amd64

  ui:
    image: %UI_IMAGE%
    container_name: erda-ui
    depends_on:
      - openapi
    env_file:
      - ./env
    environment:
      - TA_ENABLE=true
      - ENABLE_BIGDATA=false
      - ENABLE_EDGE=false
      - ONLY_FDP=false
      - TERMINUS_KEY=123
      - FDP_UI_ADDR=www.erda.cloud
    ports:
      - "80"
    restart: always
    platform: linux/amd64

  kratos-migrate:
    image: oryd/kratos:v0.7.1-alpha.1-sqlite
    environment:
      - DSN=sqlite:///var/lib/sqlite/db.sqlite?_fk=true&mode=rwc
    volumes:
      -
        type: volume
        source: kratos-sqlite
        target: /var/lib/sqlite
        read_only: false
      -
        type: bind
        source: ./kratos
        target: /etc/config/kratos
    command:
      -c /etc/config/kratos/kratos.yml migrate sql -e --yes
    restart: on-failure
    networks:
      - default

  kratos:
    container_name: kratos
    depends_on:
      - kratos-migrate
    image: oryd/kratos:v0.7.1-alpha.1-sqlite
    ports:
      - "4433" # public
      - "4434" # admin
    restart: unless-stopped
    environment:
      - DSN=sqlite:///var/lib/sqlite/db.sqlite?_fk=true
      - LOG_LEVEL=trace
    command:
      serve -c /etc/config/kratos/kratos.yml --dev
    volumes:
      -
        type: volume
        source: kratos-sqlite
        target: /var/lib/sqlite
        read_only: false
      -
        type: bind
        source: ./kratos
        target: /etc/config/kratos
    networks:
      - default

  mailslurper:
    image: oryd/mailslurper:latest-smtps
    ports:
      - "4436"
      - "4437"
    networks:
      - default

  action-runner-scheduler:
    image: %ERDA_IMAGE%
    command: /app/action-runner-scheduler
    container_name: erda-action-runner-scheduler
    env_file:
      - ./env
    ports:
      - "9500"
    restart: always
    platform: linux/amd64

  #cluster-agent:

  admin:
    image: %ERDA_IMAGE%
    command: /app/admin
    container_name: erda-admin
    env_file:
      - ./env
    environment:
      - DEBUG=false
    ports:
    - "9095"
    restart: always
    platform: linux/amd64

  cluster-dialer:
    image: %ERDA_IMAGE%
    command: /app/cluster-dialer
    container_name: erda-cluster-dialer
    env_file:
      - ./env
    environment:
      - DEBUG=false
    ports:
      - "80"
    platform: linux/amd64

  cluster-manager:
    image: %ERDA_IMAGE%
    command: /app/cluster-manager
    container_name: erda-cluster-manager
    env_file:
      - ./env
    environment:
      - DEBUG=false
    ports:
      - "9094"
    restart: always
    platform: linux/amd64

  cmp:
    image: %ERDA_IMAGE%
    command: /app/cmp
    container_name: erda-cmp
    env_file:
      - ./env
    environment:
      - ERDA_HELM_CHART_VERSION=1.1.0
      - ERDA_NAMESPACE=erda-system
      - UC_CLIENT_ID=dice
      - UC_CLIENT_SECRET=secret
    ports:
      - "9027"
    restart: always
    platform: linux/amd64

  collector:
    image: %ERDA_IMAGE%
    command: /app/collector
    container_name: erda-collector
    env_file:
      - ./env
    environment:
      - COLLECTOR_BROWSER_SAMPLING_RATE=100
      - COLLECTOR_ENABLE=true
    ports:
      - "7076"
    restart: always
    platform: linux/amd64

  core-services:
    image: %ERDA_IMAGE%
    command: /app/core-services
    container_name: erda-core-services
    depends_on:
      - mysql
      - kms
      - redis-sentinel
      - redis
    env_file:
      - ./env
    environment:
      - DEBUG=false
      - AVATAR_STORAGE_URL=file:///avatars
      - CMDB_CONTAINER_TOPIC=spot-metaserver_container
      - CMDB_GROUP=spot_cmdb_group
      - CMDB_HOST_TOPIC=spot-metaserver_host
      - CREATE_ORG_ENABLED=true
      - LISTEN_ADDR=:9526
      - UC_CLIENT_ID=dice
      - UC_CLIENT_SECRET=secret
      - LICENSE_KEY=XWoPm8I3FZuDclhuOhZ+qRPVHjXKCwSgZEOTyrMgtJg6f0Kz7QR0CyVN1ZWgbiou/OyABe7HyK1yVxDdeP1JuXcfOoGOdChTyiQfP5sdXUbferq5UkK7S44lMjNmzURlbdX8smSa13+8FQyDqz2BpDcBKMRfn2kKuF4n6n9Ls7HyVV7oWSKreEyIH3991Ug2grNEpcKip3ISVY7eGJ3uoahC9zs4fla1dzR47e5dgppHtf5WBjFgiSS+5qRi2mYa
    volumes:
      - type: volume
        source: erda-files
        target: /files
        read_only: false
      - type: volume
        source: erda-avatars
        target: /avatars
        read_only: false
    ports:
    - "9526"
    restart: always
    platform: linux/amd64

  dicehub:
    image: %ERDA_IMAGE%
    command: /app/dicehub
    container_name: erda-dicehub
    depends_on:
      - erda-migration
    env_file:
      - ./env
    ports:
      - "10000"
    environment:
      - EXTENSION_MENU={"流水线任务":["source_code_management:代码管理","build_management:构建管理","deploy_management:部署管理","version_management:版本管理","test_management:测试管理","data_management:数据治理","custom_task:自定义任务"],"扩展服务":["database:存储","distributed_cooperation:分布式协作","search:搜索","message:消息","content_management:内容管理","security:安全","traffic_load:流量负载","monitoring&logging:监控&日志","content:文本处理","image_processing:图像处理","document_processing:文件处理","sound_processing:音频处理","custom:自定义","general_ability:通用能力","new_retail:新零售能力","srm:采供能力","solution:解决方案"]}
      - RELEASE_GC_SWITCH=true
      - RELEASE_MAX_TIME_RESERVED=72
      - EXTENSION_SOURCES=https://github.com/erda-project/erda-actions.git,https://github.com/erda-project/erda-addons.git
      - EXTENSION_SOURCES_CRON=0 27 11 * * ?
    restart: always
    platform: linux/amd64

  dop:
    image: %ERDA_IMAGE%
    command: /app/dop
    container_name: erda-dop
    depends_on:
      - mysql
    env_file:
      - ./env
    environment:
      - DEBUG=true
      - GOLANG_PROTOBUF_REGISTRATION_CONFLICT=ignore
    ports:
      - "9527"
    restart: always
    platform: linux/amd64

  ecp:
    image: %ERDA_IMAGE%
    command: /app/ecp
    container_name: erda-ecp
    env_file:
      - ./env
    ports:
      - "9029"
    restart: always
    platform: linux/amd64

  eventbox:
    image: %ERDA_IMAGE%
    command: /app/eventbox
    container_name: erda-eventbox
    depends_on:
      - erda-migration
    env_file:
      - ./env
    ports:
      - "9528"
    restart: always
    platform: linux/amd64

  gittar:
    image: %ERDA_IMAGE%
    command: /app/gittar
    container_name: erda-gittar
    depends_on:
      - erda-migration
    env_file:
      - ./env
    volumes:
      - type: volume
        source: erda-gittar
        target: /repository
        read_only: false
    ports:
      - "5566"
    environment:
      - GITTAR_BRANCH_FILTER=master,develop,feature/*,support/*,release/*,hotfix/*
      - GITTAR_PORT=5566
      - UC_CLIENT_ID=dice
      - UC_CLIENT_SECRET=secret
    restart: always
    platform: linux/amd64

  hepa:
    image: %ERDA_IMAGE%
    command: /app/hepa
    container_name: erda-hepa
    depends_on:
      - erda-migration
    env_file:
      - ./env
    ports:
      - "9080"
    restart: always
    platform: linux/amd64

  monitor:
    image: %ERDA_IMAGE%
    command: /app/monitor
    container_name: erda-monitor
    env_file:
      - ./env
    ports:
      - "7096"
    restart: always
    platform: linux/amd64

  msp:
    image: %ERDA_IMAGE%
    command: /app/msp
    container_name: erda-msp
    depends_on:
      - elasticsearch
      - mysql
    env_file:
      - ./env
    environment:
      - GOLANG_PROTOBUF_REGISTRATION_CONFLICT=ignore
    ports:
      - "8080"
    restart: always
    platform: linux/amd64

  openapi:
    image: %ERDA_IMAGE%
    command: /app/openapi
    container_name: erda-openapi
    depends_on:
      - redis-sentinel
      - redis
      - erda-migration
      - pipeline
      - gittar
      - core-services
      - dicehub
      - eventbox
      - hepa
      - dop
      - orchestrator
      - msp
      - admin
    env_file:
      - ./env
    environment:
      - CREATE_ORG_ENABLED=true
      - GOLANG_PROTOBUF_REGISTRATION_CONFLICT=ignore
    ports:
      - "9529"
    restart: always
    platform: linux/amd64

  orchestrator:
    image: %ERDA_IMAGE%
    command: /app/orchestrator
    container_name: erda-orchestrator
    depends_on:
      - erda-migration
      - collector
    env_file:
      - ./env
    environment:
      - DEBUG=false
      - TENANT_GROUP_KEY=58dcbf490ef3
      - ENABLE_SPECIFIED_K8S_NAMESPACE=erda-system
    ports:
      - "8081"
      - "7080"
    restart: always
    platform: linux/amd64

  pipeline:
    image: %ERDA_IMAGE%
    command: /app/pipeline
    container_name: erda-pipeline
    depends_on:
      - erda-migration
      - orchestrator
    env_file:
      - ./env
    environment:
      - DEBUG=false
      - PIPELINE_STORAGE_URL=file:///devops/storage
    ports:
      - "3081"
    restart: always
    platform: linux/amd64

  streaming:
    image: %ERDA_IMAGE%
    command: /app/streaming
    container_name: erda-streaming
    env_file:
      - ./env
    environment:
      - BROWSER_ENABLE=true
      - BROWSER_GROUP_ID=spot-monitor-browser
      - LOG_GROUP_ID=spot-monitor-log
      - LOG_STORE_ENABLE=true
      - LOG_TTL=168h
      - METRIC_ENABLE=true
      - METRIC_GROUP_ID=spot-monitor-metrics
      - METRIC_INDEX_TTL=192h
      - TRACE_ENABLE=true
      - TRACE_GROUP_ID=spot-monitor-trace
      - TRACE_TTL=168h
    ports:
      - "7091"
    restart: always
    platform: linux/amd64

  kms:
    image: erdaproject/kms:20200608-f11445f776ba50e1f947096f57956a3f0333ab11
    container_name: erda-kms
    depends_on:
      - erda-migration
    env_file:
      - ./env
    ports:
      - "3082"
    restart: always
    platform: linux/amd64

  zookeeper:
    image: 'bitnami/zookeeper:3.7.0'
    container_name: erda-zookeeper
    ports:
      - '2181'
    environment:
      - ALLOW_ANONYMOUS_LOGIN=yes
    volumes:
      - type: volume
        source: erda-zookeeper
        target: /bitnami/zookeeper
        read_only: false
    restart: always
    platform: linux/amd64
  
  kafka:
    image: 'bitnami/kafka:2.8.0'
    container_name: erda-kafka
    ports:
      - '9092'
    environment:
      - KAFKA_BROKER_ID=1
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092
      - KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181
      - ALLOW_PLAINTEXT_LISTENER=yes
      - KAFKA_HEAP_OPTS=-Xmx256m -Xms256m
    volumes:
      - type: volume
        source: erda-kafka
        target: /bitnami/kafka
        read_only: false
    depends_on:
      - zookeeper
    restart: always
    platform: linux/amd64

  sysctl-init:
    image: busybox
    container_name: sysctl-init
    command: /bin/sh -c 'if [ $$(sysctl vm.max_map_count | cut -f2 -d=) -lt 262144 ]; then sysctl -w vm.max_map_count=262144; fi'
    privileged: true
    restart: on-failure
    platform: linux/amd64

  elasticsearch:
    image: bitnami/elasticsearch:6-debian-10
    container_name: erda-elasticsearch
    depends_on:
      - sysctl-init
    environment:
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
    volumes:
      - type: volume
        source: erda-elasticsearch
        target: /bitnami/elasticsearch/data
        read_only: false
    ports:
      - "9200"
    restart: always
    platform: linux/amd64

  etcd:
    image: bitnami/etcd:3
    container_name: erda-etcd
    volumes:
      - type: volume
        source: erda-etcd
        target: /bitnami/etcd/data
        read_only: false
    environment:
      - ALLOW_NONE_AUTHENTICATION=yes
    restart: always
    platform: linux/amd64

  mysql:
    image: erdaproject/mysql:5.7-quickstart
    container_name: erda-mysql
    ports:
      - "3306"
    volumes:
      - type: volume
        source: erda-mysql
        target: /var/lib/mysql
        read_only: false
    environment:
      - MYSQL_ROOT_PASSWORD=123456
      - TZ=Asia/Shanghai
    restart: always
    platform: linux/amd64

  mysql-healthcheck:
    image: busybox
    container_name: mysql-healthcheck
    command: /bin/sh -c 'echo "waiting for mysql ready..."; until nc -z mysql 3306; do if [ $$(($$i)) -gt 10 ];then echo "timeout waiting for mysql ready"; exit 1; fi; sleep 10; let i++; done; echo "mysql is ready"'
    depends_on:
      - mysql
    restart: "no"
    platform: linux/amd64

  erda-migration:
    image: %MIGRATION_IMAGE%
    container_name: erda-migration
    depends_on:
      - mysql
    environment:
      - TZ=Asia/Shanghai
      - MIGRATION_MYSQL_HOST=mysql
      - MIGRATION_MYSQL_PORT=3306
      - MIGRATION_MYSQL_USERNAME=root
      - MIGRATION_MYSQL_PASSWORD=123456
      - MIGRATION_MYSQL_DBNAME=erda
      - MIGRATION_DEBUGSQL=false
      - MIGRATION_SKIP_LINT=true
      - MIGRATION_SKIP_PRE_MIGRATION=true
      - MIGRATION_SKIP_MIGRATION=false
    restart: on-failure
    platform: linux/amd64

  redis-sentinel:
    image: bitnami/redis-sentinel:6.0-debian-10
    container_name: erda-redis-sentinel
    environment:
      - REDIS_MASTER_PASSWORD=123456
    depends_on:
      - redis
    restart: always
    ports:
    - "26379"
    platform: linux/amd64

  redis:
    image: bitnami/redis:6.0-debian-10
    container_name: erda-redis
    environment:
      - REDIS_PASSWORD=123456
    ports:
      - "6379"
    restart: always
    platform: linux/amd64
volumes:
  erda-mysql: {}
  erda-etcd: {}
  erda-gittar: {}
  erda-avatars: {}
  erda-files: {}
  kratos-sqlite: {}
  erda-elasticsearch: {}
  erda-kafka: {}
  erda-zookeeper: {}

networks:
  default:
    driver: bridge
    ipam:
     config:
       - subnet: 10.5.0.0/16
