module RedmineMultiColumnIssuesHelperPatch
  module IssuesHelperPatch
    unloadable
    
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain :render_custom_fields_rows, :multi_column
      end
    end
    
    module InstanceMethods
      def render_custom_fields_rows_with_multi_column(issue)
        values = issue.visible_custom_field_values(User.current)
        return if values.empty?
        ordered_values = []
        
        index = 0
        next_multi_column = next_multi_column_index(issue, index, values)
        while ordered_values.size < values.size do
          half = ((next_multi_column - index) / 2.0).ceil
          half.times do |i|
            ordered_values << values[index + i]
            ordered_values << values[index + i + half] unless index + i + half >= next_multi_column
          end
          index = next_multi_column
          if index < values.size
            ordered_values << values[index]
            next_multi_column = next_multi_column_index(issue, index + 1, values)
            index += 1
            next_multi_column = next_multi_column_index(issue, index, values)
          end
        end  
        
        s = "<tr>\n"
        n = 0
        last_multi_column = false
        hr = "<tr><td colspan='4'><hr /></td></tr>\n"
        ordered_values.compact.each do |value|
          css = "cf_#{value.custom_field.id}"
          if value.custom_field.multi_column?
            s << "</tr>\n" unless last_multi_column
            s << hr
            s << "<tr><td colspan='4' class=\"#{css}\">\n"
            s << "<p><strong>#{ h(value.custom_field.name) }</strong></p>\n"
            s << "<div class='wiki'>#{ h(show_value(value)) }</div>\n"
            s << "</td></tr>"
            n = 0
          else
            s << hr if last_multi_column
            s << "</tr>\n<tr>\n" if n > 0 && (n % 2) == 0
            s << "\t<th class=\"#{css}\">#{ h(value.custom_field.name) }:</th><td class=\"#{css}\">#{ h(show_value(value)) }</td>\n"
            n += 1
          end
          last_multi_column = value.custom_field.multi_column?
        end
        s << "</tr>\n"
        s.html_safe
      end
      
      def next_multi_column_index(issue, index, custom_field_values)
        next_index = index
        while ((next_index < custom_field_values.size) && !custom_field_values[next_index].custom_field.multi_column?) do
          next_index += 1
        end
        return next_index
      end
      
    end
    
  end
end

IssuesHelper.send(:include, RedmineMultiColumnIssuesHelperPatch::IssuesHelperPatch)
