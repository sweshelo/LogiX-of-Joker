# How to make abilities
ここでは、Arcanaのカードの効果を実装するにあたって、知っておかなければならないこと、知っておくと良いもの、守らなければならないことを解説します。Arcanaのカード効果は、LogiXで記述します。そのため、LogiXについて知っていれば効果を実装できると思うかもしれませんが、効果を待ち受けたり、決まったフローで処理を進めるために、幾つかの決まり事が存在するのです。ここで書かれている内容を無視してLogiXを実装した場合、**間違いなくバグを招きます**ので、必ず目を通してください。

## 凡例
- `Arcana/xxxx`のように`/`で区切られたワードはSlotとその位置・親子関係を示します。例では、`xxxx`Slotが`Arcana(ObjectRoot)`の直下にあることを示します。
- `{ "key": Value }`のようにJSON形式で記述されているものは、説明中で言及されているSlot内のDynamicValueVariable(->DV)を示し、多くの場合、`Value`に相当する値はDVの型を示しています。また、型名はNeosで用いられているそれとは厳密には異なる場合があります。
- `${Value}`のような表記は、`Value`という名前のDVの値を何らかの形で利用していることを示します。


## どのようにしてArcanaはカード効果を呼び出すか
> **Note** この節では「知っておくと良いこと」を解説しています

Arcanaは、特定のタイミングにおいて、Pulseの発火前に`Stack`というSlotを複製し、`Arcana/GameData/RootStack`下に移動させます。このSlotの中に`CheckStackEffect`PulseRecieverを含むLogiXがパックされており、この`Stack`Slotは、各カードの効果を適切な順番で呼び出すために機能します。その後、`Arcana/GameData/RootStack`に対して、`CheckStackEffect`Pulseを発火させます。

### `Stack`が生成されるタイミング
- ターン開始時と終了時
- ユニットがフィールドに出た時
- ユニットがアタックした時
- ユニットが〈起動〉アビリティを発動した時
- ジョーカーカードを使用した時

### `Stack`内のDV
```
{
    "Trigger": Slot,      // そのPulseを発生させる要因となったカード、ユニット、またはプレイヤー
    "Target": Slot,       // そのPulseによって影響を受けたカード、ユニット、またはプレイヤー
    "EventType": String,  // そのPulseが発生した原因
    "Value": float,       // そのPulseによって影響を受けたものが数値で表現可能な変化を伴った場合、その変化量
    "Arcana": ObjectRoot, // Arcana. ゲームオブジェクトのルート
    "Self": Slot,         // Slot自身
    "Return": Slot,       // 内部処理で利用
    "Phase": Int,         // 内部処理で利用
}
```

## どのようにしてArcanaはゲーム内の処理をカード効果LogiXへ委託するか
> **Note** この節では「知っておくと良いこと」を解説しています

Arcanaは、上記の`Stack`Slot内で、`Arcana/Dictionary/${Trigger}/LogiX`ディレクトリ内に`Stack.EventType`の値に応じた名前のSlotを検索します。この過程でヒットするSlotが存在していれば、「効果を発動し得る」と判断し、このSlotに対して`Stack.EventType`の名前でPulseを発火させます。

ここで、`Arcana/Dictionary/${Trigger}/LogiX/${Stack.EventType}`に処理が引き渡されます。`Return`Pulseを受け取ることで、Arcanaがゲーム内処理を続行します。つまり、処理が外部に引き渡されたあと、何らかの理由で`Return`されなかった/し忘れた場合、ゲームの進行が停止してしまいます。

## どのようにしてArcanaから処理を委託するLogiXを作ればよいか
> **Warning** この節では「知っておかなければならないこと」を解説しています

> **Warning** この節では「守らなければならないこと」を解説しています

ここからは、実際にカードの効果を実装するにあたって必要な手順を解説します。

### Slotを作る
カード効果の有無は、Slotの有無で判定されます。`Arcana/Dictionaly/[CardId]/LogiX`フォルダ内に、命名規則に従ってSlotを作成します。命名規則は、次のとおりです。

- <a href="#EventTypeTable">EventType表</a>に従って、EventTypeを名前のベースにします。
- 実装するカードがユニットカードの場合は接尾辞が必要です。「ユニットがフィールドに出た時」の場合、
  * 自身のみが効果の対象となる場合、`Self`を付けます
  * 自身以外のみが効果の対象となる場合、`Other`を付けます(「このユニット以外の〈獣〉ユニットが～」等)
  * 自身を含む全てのユニットが対象の場合、Slotをもう一つ作り、片方は`Self`、片方は`Other`とします。

例えば、「自身以外のユニットがアタックした時」といったテキストに対応するSlotは`AttackOther`になります。

### Dynamic Impulse Recieverを作る
上記で作成したSlot内にLogiXをパックしていきます。まずはDynamic Impulse Recieverが必要です。命名規則に従ってWith SlotのRecieverを作成します。命名規則は、次のとおりです。

- <a href="#EventTypeTable">EventType表</a>に従って、EventTypeを名前のベースにします。
- 実装するカードがユニットカードの場合は接尾辞が必要です。「ユニットがフィールドに出た時」の場合、
  * 自身のみが効果の対象となる場合、`Self`を付けます
  * 自身以外のみが効果の対象となる場合、`Other`を付けます(「このユニット以外の〈獣〉ユニットが～」等)
  * 自身を含む全てのユニットが対象の場合、Slotをもう一つ作り、片方は`Self`、片方は`Other`とします。

With SlotでPulseを受け取りますが、多くの場合、カード処理内では`Delay`を利用するでしょう。必ず受け取ったSlotを`Write`しておきましょう。

### Returnする
TODO: Returnの方法を書く

<a id="EventTypeTable"></a>

## EventType表

|EventType|概要|備考|
|:-:|:-:|:-:|
|UnitDriveFromHand|ユニットが召喚された||
|Attack|ユニットがアタックした||
|Block|ユニットがブロックした||
|Battle|ユニットが戦闘した|`Stack`には`Trigger`にアタックしたユニットが、<br>`Target`にブロックしたユニットが格納される|
|Break|ユニットが破壊された||
|Delete|ユニットが消滅された||
|Bounce|ユニットが手札に戻された||
|Damage|ユニットがダメージを受けた||
