require 'capybara/poltergeist'

# initialize Capybara+Poltergeist
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {:js_errors => false, :timeout => 5000 })
end

session = Capybara::Session.new(:poltergeist)

session.driver.headers = {
  'User-Agent' => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2564.97 Safari/537.36"
}

# IEYASU にログイン
session.visit "https://ieyasu.co/spicelife/login"
login_id_input = session.find("input[name='user[login_id]']")
login_id_input.native.send_key(ENV['IEYASU_LOGIN_ID'])
password_input = session.find("input[name='user[password]']")
password_input.native.send_key(ENV['IEYASU_PASSWORD'])
session.click_on("ログイン")

# IEYASU で修正が必要な日付を列挙
# 別の月の修正をしたい場合は、ここの URL を変更する(例: "https://ieyasu.co/works/2016-05")
session.visit "https://ieyasu.co/works"

edit_urls = session.all("table.tableCalendar tr").inject([]) do |r,tr|
  next r if tr.has_selector?("th")
  next r if tr.find("td.cellType").text.split(/\s/)[0] != '出勤'
  next r if tr.find("td.cellTime01").text.length != 0

  s = tr.find("td.cellDate").text.split(' ')
  url = tr.find("td.cellDate a")['href']
  date = Date.parse("#{url.split('d=')[1]}-#{s[0]}")

  r << { url: url, date: date }
end

# 編集ページで勤務時間を入力
edit_urls.each do |h|
  next if Date.today < h[:date]

  puts "#{h[:date].to_s} の勤務時間を入力(#{h[:url]})"
  session.visit(h[:url])

  work_start_at_input = session.find("#work_start_at_str")
  work_start_at_input.trigger('click')
  work_start_at_input.native.send_key('10:00')
  work_end_at_input = session.find("#work_end_at_str")
  work_end_at_input.trigger('click')
  work_end_at_input.native.send_key('19:00')

  session.click_on("登録する")
end

puts "done =)"
