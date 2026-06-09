%w[
  KOT
  DOM
  LAS
  RAK
  ROK
  SOK
  MAK
  TOR
  OKO
  PIES
  RYBA
  WODA
  LATO
  ZIMA
  TEST
  MAMA
  TATA
].each do |value|
  Word.find_or_create_by!(value: value, language: "pl")
end
