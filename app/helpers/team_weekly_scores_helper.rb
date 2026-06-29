module TeamWeeklyScoresHelper
  CHART_WIDTH = 640
  CHART_HEIGHT = 220
  CHART_PADDING_X = 28
  CHART_PADDING_Y = 18
  SCORE_MIN = BigDecimal("1.0")
  SCORE_MAX = BigDecimal("5.0")

  def score_chart_points(points, width: CHART_WIDTH, height: CHART_HEIGHT)
    return "" if points.blank?

    points.each_with_index.map do |point, index|
      x = chart_x(index, points.size, width)
      y = chart_y(point.fetch(:value), height)
      "#{x},#{y}"
    end.join(" ")
  end

  def score_chart_point_positions(points, width: CHART_WIDTH, height: CHART_HEIGHT)
    points.each_with_index.map do |point, index|
      point.merge(
        x: chart_x(index, points.size, width),
        y: chart_y(point.fetch(:value), height)
      )
    end
  end

  def score_percent(value)
    return 0 unless value

    value = value.to_d.clamp(SCORE_MIN, SCORE_MAX)
    (((value - SCORE_MIN) / (SCORE_MAX - SCORE_MIN)) * 100).round
  end

  def score_delta_class(delta)
    return "is-flat" if delta.blank? || delta.zero?

    delta.positive? ? "is-up" : "is-down"
  end

  def score_delta_text(delta)
    return "±0.00" if delta.blank? || delta.zero?

    "#{delta.positive? ? '+' : ''}#{number_with_precision(delta, precision: 2)}"
  end

  private

  def chart_x(index, count, width)
    return width / 2 if count == 1

    span = width - (CHART_PADDING_X * 2)
    (CHART_PADDING_X + (span * index.to_f / (count - 1))).round(2)
  end

  def chart_y(value, height)
    value = value.to_d.clamp(SCORE_MIN, SCORE_MAX)
    span = height - (CHART_PADDING_Y * 2)
    ratio = (value - SCORE_MIN) / (SCORE_MAX - SCORE_MIN)
    (height - CHART_PADDING_Y - (span * ratio)).round(2)
  end
end
