module ApplicationHelper
  def login_greeting(now = Time.zone.now)
    case now.hour
    when 0...10
      "おはようございます。"
    when 10...17
      "こんにちは。"
    else
      "こんばんは。"
    end
  end
end
