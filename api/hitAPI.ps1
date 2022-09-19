if ( !(Test-Path "./data")) {
  mkdir ./data
}

@(
    "Ver.2.3EX2",
    "Ver.2.3EX1",
    "Ver.2.3",
    "Ver.2.2EX",
    "Ver.2.2",
    "Ver.2.1EX",
    "Ver.2.1",
    "Ver.2.0EX3",
    "Ver.2.0EX2",
    "Ver.2.0EX1",
    "Ver.2.0",
    "Ver.1.4EX3",
    "Ver.1.4EX2",
    "Ver.1.4EX1",
    "Ver.1.4",
    "Ver.1.3EX2",
    "Ver.1.3EX1",
    "Ver.1.3",
    "Ver.1.2EX",
    "Ver.1.2",
    "Classic",
    "Sp",
    "joker",
    "Virus",
    "Interceptunit",
    "PR"
) | %{
  echo "https://coj.sega.jp/player/card/data/card_list_$_.json";
  $(iwr "https://coj.sega.jp/player/card/data/card_list_$_.json").Content > "./data/$_.json";
}
