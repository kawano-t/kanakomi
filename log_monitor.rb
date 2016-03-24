#!/usr/bin/ruby
###########################3
## 20140820 made
## 20140826 sendmail機能追加
######
## 使用例
## 
#####

require 'mail'
require 'openssl'


##日付
datetime = `date`
datetime.chomp!


##ログファイルオープン
    begin
        log_filename = "/var/log/log_aleart.log"
        log_file = File.open(log_filename, "a")
    rescue => e
        puts e
        puts log_filename + "を開くことができません"
        exit!
    end



##ログ出力文字列定義
def usage()
    log_file.puts "\nusage : /usr/local/bin/log_monitor.rb filename string"
    log_file.puts "          filenameで指定されたファイルをstringで監視し、マッチすれば終了します"
end

 
##SMTPメール配送設定
Mail.defaults do
  delivery_method :smtp, {
    :address => "127.0.0.1",
    :port => 25,
  }
end



##メイン文#########
if (ARGV[0].nil? || ARGV[1].nil?)
    log_file.puts "引数が足りません"
    usage()
    exit!
else
    begin
        filename = ARGV[0]
        file = File.open(filename, "r")
        filesize = File.size?(filename)
        if (filesize == nil)
            filesize = 0
        end
    rescue => e
        log_file.puts e
        log_file.puts filename + "を開くことができません"
        usage
        exit!
    end
    str = ARGV[1]
    log_file.puts datetime + " ファイル" + filename + " を文字列" + str + " で監視します"
end

#前回処理した行まで移動
begin
        line_filename = "/usr/local/bin/log_monitor.linenum"
        line_file = File.open(line_filename, "r")
        line_filesize = File.size?(line_filename)
        if (line_filesize == nil)
	    line_count = 0
        else
            line_count = line_file.gets.chomp.to_i()
	    line_file.close()
        end
rescue => e
        log_file.puts e
        log_file.puts datetime + line_filename + "を開くことができません"
        usage
        exit!
end

######p "line_count=" + line_count.to_s

#file.seek(file_seek_line,IO::SEEK_DATA)


begin
    # 対象行までの読み込みループ
    now_line_count = 0
    while (true) do
        line = file.gets()
	now_line_count += 1

	if (now_line_count <= line_count);then
	else
######		puts "line_count " + line_count.to_s
		line_count += 1
       	 	if (! line.nil?)
        		if ( /#{str}/ =~ $_ )
               			log_file.puts datetime + "*** MATCH : " + $_
                                mail = Mail.new do
                                    to MAILTO
                                    from MAILFROM
                                    subject 'ログイン検知'
                                    body $_
                                end
                                mail.charset = 'utf-8' 
                                mail.deliver!
     	 		end
        	else
 ##           		puts "break" + line_count
            			break
		end 
       	end           
    end
    line_file = File.open(line_filename, "w")
 
   # nilの行分を-1
    line_file.puts now_line_count - 1

ensure
    if (! file.closed?)
        file.close()
        line_file.close()
        log_file.close()
    end
    exit!
end

