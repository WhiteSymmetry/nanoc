class Nanoc::ExtraCoreExtTimeTest < Nanoc::TestCase
  def test___nanoc_to_iso8601_date
    assert_equal('2008-05-19', Time.utc(2008, 5, 19, 14, 20, 0, 0).__nanoc_to_iso8601_date)
  end

  def test___nanoc_to_iso8601_time
    assert_equal('2008-05-19T14:20:00Z', Time.utc(2008, 5, 19, 14, 20, 0, 0).__nanoc_to_iso8601_time)
  end
end
