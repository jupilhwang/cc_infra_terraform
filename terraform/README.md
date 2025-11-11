# Confluent Cloud ETL Pipeline with Terraform

이 Terraform 설정은 Confluent Cloud에서 다음과 같은 ETL 파이프라인을 구성합니다:
- Environment와 Standard Kafka Cluster
- Service Account와 Admin Role
- MySQL CDC Connector (Debezium v2)
- S3 Sink Connector
- 필요한 ACL 설정

## 아키텍처 구성

```
MySQL Database 
    ↓ (CDC)
Kafka Topic (mysql-cdc)
    ↓ (Stream Processing)
Kafka Topic (s3-sink)
    ↓ (S3 Sink)
AWS S3 Bucket
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
GRANT ALL PRIVILEGES ON bunjang.* TO 'debezium_user'@'%';
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
                "arn:aws:s3:::bunjang-data-lake",
                "arn:aws:s3:::bunjang-data-lake/*"
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
confluent_cloud_api_key    = "YOUR_ACTUAL_API_KEY"
confluent_cloud_api_secret = "YOUR_ACTUAL_API_SECRET"

# MySQL 설정
mysql_hostname = "your-mysql-rds-endpoint.amazonaws.com"
mysql_username = "debezium_user"
mysql_password = "your_secure_password"

# AWS S3 설정
s3_bucket_name = "your-actual-bucket-name"
aws_access_key_id = "YOUR_AWS_ACCESS_KEY"
aws_secret_access_key = "YOUR_AWS_SECRET_KEY"
```

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
- **Environment**: `bunjang-production`
- **Cluster**: Standard cluster (Single Zone)
- **Region**: `ap-northeast-2` (Seoul)

### Service Account & Security
- **Service Account**: CloudClusterAdmin 권한
- **API Keys**: Kafka 클러스터 접근용
- **ACLs**: 토픽별 읽기/쓰기 권한 설정

### Topics
- **MySQL CDC Topic**: `bunjang.mysql.cdc` (6 partitions)
- **S3 Sink Topic**: `bunjang.s3.sink` (6 partitions)

### Connectors
- **MySQL CDC Connector**: Debezium MySQL Source v2
- **S3 Sink Connector**: JSON 형식으로 시간별 파티셔닝

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
- Schema Registry 추가 고려 (Avro 스키마 관리)