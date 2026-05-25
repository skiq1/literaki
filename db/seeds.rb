%w[
  KOT
  DOM
  LAS
  RAK
  ROK
  SOK
  MAK
  TOR
  MAMA
  TATA
].each do |value|
  Word.find_or_create_by!(value: value, language: "pl")
end
