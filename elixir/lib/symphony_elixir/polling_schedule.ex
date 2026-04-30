defmodule SymphonyElixir.PollingSchedule do
  @moduledoc false

  @day_ms 86_400_000

  @spec bounded_delay_ms(non_neg_integer(), term(), DateTime.t()) :: non_neg_integer()
  def bounded_delay_ms(requested_delay_ms, nil, _now_utc)
      when is_integer(requested_delay_ms) and requested_delay_ms >= 0,
      do: requested_delay_ms

  def bounded_delay_ms(requested_delay_ms, active_window, now_utc)
      when is_integer(requested_delay_ms) and requested_delay_ms >= 0 do
    start_ms = time_to_ms(active_window.start)
    end_ms = time_to_ms(active_window.end)
    offset_ms = offset_to_ms(active_window.utc_offset)
    local_ms = DateTime.to_unix(now_utc, :millisecond) + offset_ms
    local_day_ms = Integer.mod(local_ms, @day_ms)

    cond do
      local_day_ms < start_ms ->
        start_ms - local_day_ms

      local_day_ms >= end_ms ->
        @day_ms - local_day_ms + start_ms

      local_day_ms + requested_delay_ms < end_ms ->
        requested_delay_ms

      true ->
        @day_ms - local_day_ms + start_ms
    end
  end

  defp time_to_ms(<<hour_text::binary-size(2), ":", minute_text::binary-size(2)>>) do
    {hour, ""} = Integer.parse(hour_text)
    {minute, ""} = Integer.parse(minute_text)
    (hour * 60 + minute) * 60_000
  end

  defp offset_to_ms(<<sign::binary-size(1), hour_text::binary-size(2), ":", minute_text::binary-size(2)>>) do
    {hour, ""} = Integer.parse(hour_text)
    {minute, ""} = Integer.parse(minute_text)
    multiplier = if sign == "-", do: -1, else: 1
    multiplier * (hour * 60 + minute) * 60_000
  end
end
