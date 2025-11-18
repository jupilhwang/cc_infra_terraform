# Confluent Cloud ETL Pipeline with Terraform

이 Terraform 설정은 Confluent Cloud에서 다음과 같은 ETL 파이프라인을 구성합니다:
- Environment와 Standard Kafka Cluster
- Service Account와 EnvironmentAdmin Role
- MySQL CDC Connector (Debezium v2) - Avro 포맷
- S3 Sink Connector - Parquet 포맷으로 저장
- Logs Topic (무한 보존)
- 필요한 ACL 설정

## 아키텍처 구성

```
MySQL Database 
    ↓ (CDC - Avro)
Kafka Topics:
  - mysql.cdc (Avro format)
  - s3.sink (Avro format) 
  - logs (무한 보존)
    ↓ (S3 Sink)
AWS S3 Bucket (Parquet format with gzip)
```

## 사전 준비

### 1. Confluent Cloud API Key 생성
1. [Confluent Cloud Console](https://confluent.cloud/) 로그인
2. Account Settings → API Keys → Create Key
3. Cloud API Key 생성 (Global scope)

### 2. MySQL 데이터베이스 설정
MySQL에서 CDC를 위한 설정이 필요합니다:

```sql
-- CDC 전용 사용자 생성
CREATE USER 'debezium_user'@'%' IDENTIFIED BY 'your_password';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'debezium_user'@'%';
GRANT ALL PRIVILEGES ON production.* TO 'debezium_user'@'%';
FLUSH PRIVILEGES;

-- MySQL 설정 확인 (my.cnf)
-- server-id = 1001
-- log-bin = mysql-bin
-- binlog_format = ROW
-- binlog_row_image = FULL
```

### 3. AWS S3 설정
S3 버킷과 IAM 사용자/역할 설정:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::data-lake",
                "arn:aws:s3:::data-lake/*"
            ]
        }
    ]
}
```

## 사용 방법

### 1. 설정 파일 수정
`terraform.tfvars` 파일의 값들을 실제 환경에 맞게 수정:

```hcl
# API 인증정보
project_name             = "bunjang-poc"
confluent_cloud_api_key    = "YOUR_ACTUAL_API_KEY"
confluent_cloud_api_secret = "YOUR_ACTUAL_API_SECRET"

# 환경 및 스키마 거버넌스 설정
cloud_provider          = "AWS"
region                  = "ap-northeast-2"
schema_registry_package = "ADVANCED"
schema_registry_region  = "ap-northeast-2"

# MySQL 설정
mysql_hostname = "your-mysql-rds-endpoint.amazonaws.com"
mysql_username = "debezium_user"
mysql_password = "your_secure_password"

# AWS S3 설정
s3_bucket_name = "your-actual-bucket-name"
aws_access_key_id = "YOUR_AWS_ACCESS_KEY"
aws_secret_access_key = "YOUR_AWS_SECRET_KEY"
```

> 참고: Terraform이 `project_name` 값을 모든 Confluent 리소스 이름의 prefix로 자동 적용합니다 (예: `bunjang-poc-production`, `bunjang-poc-mysql.cdc`).

### 2. Terraform 실행

```bash
# 초기화
terraform init

# 계획 확인
terraform plan

# 적용
terraform apply
```

### 3. 배포 확인

```bash
# 출력값 확인
terraform output

# 특정 값만 확인
terraform output kafka_cluster_bootstrap_endpoint
terraform output mysql_connector_status_url
```

## 주요 리소스

### Environment & Cluster

- **Environment**: `bunjang-poc-production`
- **Cluster**: `bunjang-poc-kafka-cluster` (Standard, Single Zone)
- **Region**: `ap-northeast-2` (Seoul)
- **Schema Governance**: Schema Registry Advanced package deployed in `ap-northeast-2`

### Service Account & Security

- **Service Account**: `bunjang-poc-app-service-account` (EnvironmentAdmin)
- **API Keys**: `bunjang-poc-app-manager-kafka-api-key` (Kafka 접근)
- **ACLs**: 토픽별 읽기/쓰기 권한 설정

### Topics

- **MySQL CDC Topic**: `bunjang-poc-mysql.cdc` (6 partitions) - Avro 포맷
- **S3 Sink Topic**: `bunjang-poc-s3.sink` (6 partitions) - Avro 포맷
- **Logs Topic**: `bunjang-poc-logs` (6 partitions) - 무한 보존

### Connectors

- **MySQL CDC Connector**: `bunjang-poc-mysql-cdc-v2` (Debezium v2, Avro output)
- **S3 Sink Connector**: `bunjang-poc-s3-data-sink` (Avro input → Parquet 저장, gzip)

## 데이터 포맷 및 스키마

### Avro 및 Parquet 사용의 장점

**Avro (Kafka Topics)**:

- 스키마 진화: 스키마 변경 시 하위 호환성 보장
- 압축 효율: JSON 대비 더 효율적인 직렬화
- 타입 안정성: 강력한 타입 시스템으로 데이터 무결성 보장
- Schema Registry: Confluent의 Schema Registry와 자동 통합

**Parquet (S3 Storage)**:

- 컬럼형 저장: 분석 쿼리에 최적화된 저장 구조
- 압축 효율: 높은 압축률로 스토리지 비용 절약
- 빠른 쿼리: Amazon Athena, Spark 등에서 빠른 성능
- 스키마 보존: 메타데이터와 스키마 정보 포함

### S3 파일 구조

Parquet 파일들이 시간별로 파티셔닝되어 저장됩니다:

```text
s3://data-lake/
├── year=2025/
│   ├── month=11/
│   │   ├── day=11/
│   │   │   ├── hour=10/
│   │   │   │   └── s3.sink+0+0000000000.parquet
│   │   │   │   └── s3.sink+1+0000000000.parquet
```

## 모니터링 및 관리

### Confluent Cloud Console

생성된 리소스는 Confluent Cloud Console에서 모니터링할 수 있습니다:

- Environment → Clusters → Connectors
- Topics → Messages 탭에서 실시간 데이터 확인

### 커넥터 상태 확인

```bash
# MySQL CDC 커넥터 상태
curl -u {api_key}:{api_secret} \
  {kafka_rest_endpoint}/connectors/{mysql_connector_name}/status

# S3 Sink 커넥터 상태
curl -u {api_key}:{api_secret} \
  {kafka_rest_endpoint}/connectors/{s3_connector_name}/status
```

## 문제 해결

### 일반적인 문제들

1. **MySQL 연결 실패**
   - MySQL의 binlog 설정 확인
   - 네트워크 접근 권한 확인
   - 사용자 권한 확인

2. **S3 연결 실패**
   - AWS 자격증명 확인
   - S3 버킷 권한 확인
   - 리전 설정 확인

3. **커넥터 실패**
   - Confluent Cloud Console에서 로그 확인
   - 토픽 권한 설정 확인

### 리소스 정리

```bash
# 모든 리소스 삭제
terraform destroy
```

## 비용 최적화

- Standard 클러스터는 시간당 과금되므로, 개발/테스트 환경에서는 Basic 클러스터 고려
- 커넥터별로 별도 과금되므로, 불필요한 커넥터는 정리
- S3 저장소 비용 고려하여 lifecycle policy 설정 권장

## 보안 고려사항

- API Key와 비밀번호는 Terraform 상태 파일에 평문으로 저장되므로 상태 파일 보안 필수
- 프로덕션 환경에서는 HashiCorp Vault 등 시크릿 관리 도구 사용 권장
- VPC 피어링이나 Private Link 설정 고려

## 확장 고려사항

- 토픽 파티션 수는 예상 처리량에 따라 조정
- 커넥터의 `tasks.max` 값으로 병렬 처리 조정
- Schema Registry가 자동으로 활성화되어 Avro 스키마 관리
- 무한 보존 logs 토픽을 활용한 로그 수집 파이프라인 구축
- Parquet 파일을 활용한 데이터 웨어하우스 구축 (Athena, Redshift, BigQuery 등)

## Provider 버전

- **Confluent Provider**: `~> 2.51.0` (최신 버전)
- 정기적인 provider 업데이트로 최신 기능 및 보안 패치 적용
