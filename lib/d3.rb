require 'date'
require 'json'

module D3
  def self.alert_frequency(incidents)
    incidents.map do |incident|
      name = "#{incident['input_type']} #{incident['entity']} #{incident['check']}"
      {
        :name => name,
        :data => incident['count']
      }
    end.slice(0, 50).to_json
  end

  def self.noise_candidates(incidents)
    incidents.map do |incident|
      name = "#{incident['input_type']} #{incident['entity']} #{incident['check']}"
      # Truncate long check names by removing everything after and including the second -
      {
        :name => name,
        :data => incident['count']
      }
    end.slice(0, 50).to_json
  end

  def self.alert_response(opts)
    return {} unless opts[:incidents]
    if opts[:aggregated]
      ack_data, resolve_data = %w(ack resolve).map do |type|
        opts[:aggregated].map do |i|
          [i['time'] * 1000, i["mean_#{type}"]]
        end
      end.compact.sort
      ack_name = 'Average time until acknowledgement of alert'
      resolve_name = 'Average time until alert was resolved'
    else
      ack_data, resolve_data = %w(ack resolve).map do |type|
        opts[:incidents].map do |i|
          {
            :name => i['incident_key'],
            :x => i['alert_time'] * 1000,
            :y => i["time_to_#{type}"]
          }
        end.compact.sort_by { |k| k[:x] }
      end
      ack_name = 'Time until acknowledgement of alert'
      resolve_name = 'Time until alert was resolved'
    end

    count_data = opts[:count].map do |i|
      [i['time'] * 1000, i['count']]
    end.compact.sort

    [
      {
        :key => "Number of alerts per #{opts[:count_group_by]}",
        :values => count_data,
      }, {
        :key => ack_name,
        :values => ack_data,
      }, {
        :key => resolve_name,
        :values => resolve_data,
      }
    ].to_json
  end

  def self.wake_up(incidents)
    series = {}
    incidents.map do |incident|
      name = incident['check']
      if !series[name]
        series[name] = 1
      else
        series[name] = series[name] + 1
      end
    end
    series = series.sort_by {|_key, value| value}.reverse
    series.map do | name, count |
      {
        :name => name,
        :data => count
      }
    end.slice(0, 50).to_json
  end

  def self.response_hours(opts)
    series = {}
    opts.each do | o |
      time_stamp = DateTime.strptime(o['time'].to_s,'%s')
      if !series[time_stamp.strftime('%a')]
        series[time_stamp.strftime('%a')] = {}
      end
      if !series[time_stamp.strftime('%a')][time_stamp.hour]
        series[time_stamp.strftime('%a')][time_stamp.hour] = {}
        series[time_stamp.strftime('%a')][time_stamp.hour]['count'] = 0
        series[time_stamp.strftime('%a')][time_stamp.hour]['checks'] = []
      end
      series[time_stamp.strftime('%a')][time_stamp.hour]['count'] = series[time_stamp.strftime('%a')][time_stamp.hour]['count'] + o['check_count']
      series[time_stamp.strftime('%a')][time_stamp.hour]['checks'].push("#{o['check']}: #{o['check_count']}")
    end
    return series.to_json
  end
end
