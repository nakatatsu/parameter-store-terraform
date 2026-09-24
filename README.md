# parameter-store-terraform

パスワードやAPIキー等、Webアプリケーションに付き物の機密情報をセキュアに取り扱うためのサンプルです。

パラメータファイルをSOPSで暗号化しつつ、リポジトリ自体をAWS SSM Parameter Store専用に隔離している点がポイントです。

## なぜこうするのか？

機密情報をenvファイルに書かず、AWS SSM Parameter Storeに保存して利用するのは良いプラクティスです。

しかしそれだけでなく、機密情報を格納したファイルはリポジトリを専用に分けるべきです。何故なら下記のメリットがあるためです。

- AIエージェントから隔離しやすい

- 利用者を最小限に制限しやすい

逆に普段使いのリポジトリに一緒にしていると、AIエージェントにうっかり読ませてしまったり、あるいは本来見せるべきでない相手に機密情報を見せてしまうといった事故を起こすもととなります。このためここではAWS SSM Parameter Store専用のリポジトリとしています。

また、利用者を限定したとしても平文でgitに機密情報を保存すべきではありません。暗号化した上で保存することが望ましいです。そこでSOPSを用いています。

つまりは機密情報をGitで管理しつつも、セキュリティも確保するのが狙いです。

## Requirements

利用に必要なツールは下記の通りです。

- Terraform >= 1.15.6

- SOPS

- age

- AWS CLI v2

同梱のDevContainerを参照してください。

## 試し方

DevContainerで開き、下記を実行します。本当にパラメータストアに作成されるため、必ず開発用の環境を用いてください。

作業概要は下記の通りです。

1. 暗号化のためage鍵を作成します

2. 作成した鍵で機密情報を記したファイルを暗号化します

3. 暗号化したファイルをTerraformに渡してAWSに反映。AWS Parameter Storeに値が作られることを確認します

### 暗号化からAWSへの反映まで

1. age鍵ペアを作り、SOPSが用いる秘密鍵ファイルのパスを指定します。`/workspace/keys.txt`は秘密鍵のため、公開しないでください。また、本来はKMSの利用が望ましいです。

   ```bash
   age-keygen -o /workspace/keys.txt
   export SOPS_AGE_KEY_FILE=/workspace/keys.txt
   ```

2. `.sops.yaml`を以下の内容にします。`<公開鍵>`は、手順1で表示された`age1...`に置き換えます。

   ```yaml
   creation_rules:
     - path_regex: ^development/
       age: <公開鍵>
   ```

3. `development/secrets.yaml`を暗号化します。

   ```bash
   sops encrypt --output development/secrets.enc.yaml development/secrets.yaml
   ```

4. AWSにログインし、適用します。

   ここではIAM Identity Centerを前提としていますが、各自、自己の環境にあわせて読み替えてください。

   ```bash
   aws configure sso --use-device-code
   aws sso login --profile <profile> --use-device-code
   export AWS_PROFILE=<profile>
   terraform -chdir=development init
   terraform -chdir=development plan
   terraform -chdir=development apply
   ```

### 暗号化したファイルの編集方法

1. `sops edit`で編集します。復号した内容が開き、保存して閉じると再暗号化されます。

   ```bash
   sops edit development/secrets.enc.yaml
   ```

   一旦ファイルを復号してから好きなエディタで編集する方法もあります。ただし再暗号化を忘れないよう、また誤って復号したファイルをgitに保存しないよう注意してください。

   ```bash
   sops decrypt --output development/secrets.yaml development/secrets.enc.yaml
   vim development/secrets.yaml
   sops encrypt --output development/secrets.enc.yaml development/secrets.yaml
   ```

## Directory

```
.
├── .sops.yaml     暗号化ルール（ディレクトリごとの鍵）
├── development/   ルートディレクトリ。必要に応じて増やします。環境名+プロジェクト名で細かく切ってもよいです
└── ssm-params/    共通モジュール
```

## その他重要なこと

- 暗号化前のファイル（`secrets.yaml`）は本来gitignoreで除外するのが正しいです。今回は例示のためあえてコメントアウトしています。
- セキュリティを優先してStateファイルに値を残さないようにしているのですが、この代償に毎回差分がでる状況です。安定した回避方法が見つからず、やむなく全部差分で出るようにしています。PRで変更を確認することは可能なため、取り扱う量が少なければ問題ないのですが、莫大なパラメータ数になると厳しいです。terraform本体の改善を期待したいところですが、当面はルートディレクトリ側で細かく分けてあげるといったハックでしのぐしかなさそうです。


## 参考

- [terraform-provider-sopsとEphemeral valuesを使ってTerraformでシークレットを安全に扱う](https://tech.guitarrapc.com/entry/2026/01/06/230000)