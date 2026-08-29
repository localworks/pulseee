require "rails_helper"

RSpec.describe WeeklyScoreNote do
  let(:author) { User.create!(name: "記録者", email: "note-author@example.com") }

  it "requires one note per week and a body within the maximum length" do
    WeeklyScoreNote.create!(author: author, week_start_on: Date.new(2026, 8, 3), body: "施策を開始")

    assert_not WeeklyScoreNote.new(author: author, week_start_on: Date.new(2026, 8, 3), body: "別のメモ").valid?
    assert WeeklyScoreNote.new(
      author: author,
      week_start_on: Date.new(2026, 8, 10),
      body: "あ" * WeeklyScoreNote::MAX_LENGTH
    ).valid?
    assert_not WeeklyScoreNote.new(
      author: author,
      week_start_on: Date.new(2026, 8, 17),
      body: "あ" * (WeeklyScoreNote::MAX_LENGTH + 1)
    ).valid?
  end
end
