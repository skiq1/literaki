BASIC_WORDS = %w[
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
].freeze

BASIC_WORDS.each do |value|
  Word.find_or_create_by!(value: value, language: "pl")
end

SJP_ZIP_PATH = Rails.root.join(ENV.fetch("SJP_ZIP_PATH", "sjp-20260601.zip"))
SJP_ENTRY_NAME = ENV.fetch("SJP_ENTRY_NAME", "slowa.txt")
SJP_EXPECTED_WORDS_COUNT = ENV.fetch("SJP_EXPECTED_WORDS_COUNT", 3_240_240).to_i
SJP_BATCH_SIZE = ENV.fetch("SJP_BATCH_SIZE", 5_000).to_i

def import_sjp_words(zip_path:, entry_name:, batch_size:)
  if ActiveRecord::Base.connection.adapter_name.match?(/sqlite/i)
    import_sjp_words_with_sqlite_cli(zip_path: zip_path, entry_name: entry_name)
  else
    import_sjp_words_with_active_record(zip_path: zip_path, entry_name: entry_name, batch_size: batch_size)
  end
end

def import_sjp_words_with_sqlite_cli(zip_path:, entry_name:)
  started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  timestamp = Time.current
  tsv_path = Rails.root.join("tmp", "sjp-words-#{Process.pid}.tsv")
  database_path = ActiveRecord::Base.connection_db_config.database
  processed = write_sjp_words_tsv(zip_path: zip_path, entry_name: entry_name, tsv_path: tsv_path, timestamp: timestamp)

  ActiveRecord::Base.connection_pool.disconnect!

  sql = <<~SQL
    .bail on
    PRAGMA temp_store = MEMORY;
    CREATE TEMP TABLE sjp_import_words(
      value TEXT NOT NULL,
      language TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
    .mode tabs
    .import #{tsv_path} sjp_import_words
    BEGIN IMMEDIATE;
    INSERT OR IGNORE INTO words(value, language, created_at, updated_at)
    SELECT value, language, created_at, updated_at
    FROM sjp_import_words;
    COMMIT;
  SQL

  IO.popen([ "sqlite3", database_path.to_s ], "w") { |sqlite| sqlite.write(sql) }
  raise "SJP import failed: sqlite3 #{database_path}" unless $?.success?

  elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
  puts "SJP import processed #{processed} words in #{elapsed.round(1)}s"
ensure
  File.delete(tsv_path) if defined?(tsv_path) && tsv_path && File.exist?(tsv_path)
end

def write_sjp_words_tsv(zip_path:, entry_name:, tsv_path:, timestamp:)
  processed = 0
  command = [ "unzip", "-p", zip_path.to_s, entry_name ]
  formatted_timestamp = timestamp.to_fs(:db)

  File.open(tsv_path, "w:UTF-8") do |file|
    IO.popen(command, "r:UTF-8") do |stream|
      stream.each_line do |line|
        word = line.strip.upcase
        next if word.blank?

        file.write("#{word}\tpl\t#{formatted_timestamp}\t#{formatted_timestamp}\n")
        processed += 1
      end
    end
  end

  raise "SJP import failed: #{command.join(' ')}" unless $?.success?

  processed
end

def import_sjp_words_with_active_record(zip_path:, entry_name:, batch_size:)
  started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  imported = 0
  batch = []
  timestamp = Time.current

  command = [ "unzip", "-p", zip_path.to_s, entry_name ]

  IO.popen(command, "r:UTF-8") do |stream|
    stream.each_line do |line|
      word = line.strip.upcase
      next if word.blank?

      batch << { value: word, language: "pl", created_at: timestamp, updated_at: timestamp }

      next if batch.size < batch_size

      Word.insert_all(batch, unique_by: :index_words_on_value_and_language)
      imported += batch.size
      batch.clear
    end
  end

  raise "SJP import failed: #{command.join(' ')}" unless $?.success?

  unless batch.empty?
    Word.insert_all(batch, unique_by: :index_words_on_value_and_language)
    imported += batch.size
  end

  elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
  puts "SJP import processed #{imported} words in #{elapsed.round(1)}s"
end

if ENV.fetch("IMPORT_SJP_WORDS", "true") == "true"
  if File.exist?(SJP_ZIP_PATH)
    current_words_count = Word.where(language: "pl").count

    if current_words_count >= SJP_EXPECTED_WORDS_COUNT
      puts "SJP import skipped: #{current_words_count} Polish words already present"
    else
      puts "SJP import started from #{SJP_ZIP_PATH}"
      import_sjp_words(zip_path: SJP_ZIP_PATH, entry_name: SJP_ENTRY_NAME, batch_size: SJP_BATCH_SIZE)
    end
  else
    message = "SJP import failed: #{SJP_ZIP_PATH} not found"
    raise message if Rails.env.production?

    puts message
  end
else
  puts "SJP import skipped: IMPORT_SJP_WORDS is false"
end
