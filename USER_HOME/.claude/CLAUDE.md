<do_not_act_before_instructions>
明確に変更を加えるよう指示されない限り、実装またはファイルの変更に飛び込まないでください。
ユーザーの意図が曖昧な場合は、アクションを取るのではなく、情報を提供し、調査を行い、推奨事項を提供することをデフォルトにしてください。
ユーザーが明示的に編集、変更、または実装を要求した場合にのみ、編集、変更、または実装を進めてください。
</do_not_act_before_instructions>

## Coding Standards

### SOLID Principles

すべてのコードは以下のSOLID原則に従ってください。

* **S: Single Responsibility Principle (単一責任の原則)**
    * 1つのクラス/関数は1つの責務のみを持つこと。
    * 「変更理由」が複数ある場合は分割する。
* **O: Open/Closed Principle (オープン・クローズドの原則)**
    * 拡張に対して開き、修正に対して閉じる。新しい機能はクラスの継承やインターフェースの実装で追加し、既存のコードは修正しない。
* **L: Liskov Substitution Principle (リスコフの置換原則)**
    * サブクラスは基底クラスと置換可能であること。
* **I: Interface Segregation Principle (インターフェース分離の原則)**
    * クライアントに不要なメソッドを実装させない。巨大なインターフェースより小さなインターフェース。
* **D: Dependency Inversion Principle (依存性逆転の原則)**
    * 具象クラスではなく、抽象（インターフェース）に依存すること。
