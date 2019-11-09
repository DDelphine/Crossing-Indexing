require_relative "main.rb"


dwarf_dump= `llvm-dwarfdump --debug-line #{ARGV[0]}`
assembly = `objdump --disassemble #{ARGV[0]}` 
lookup_table_master = readdwarf(dwarf_dump)
lookup_table = lookup_table_master[0]
unused_table = lookup_table_master[1]
puts "Lookup Table"
puts lookup_table

#Create html header
result = "<!DOCTYPE html> 
    <html>
            <h1>Cross Indexing<h1>
            <h2>CSC 254 Assignment 4</h2>
            <h3>Mingzhe Du & Advaith Suresh</h3>
            <style>
            table {
            border-collapse: collapse;
            width: 100%;
            }
            th, td {
            text-align: left;
            padding: 8px;
            }
            tr:nth-child(odd) {background-color: #f2f2f2;}
</style>
            <div>"
#add first row of assembly table
assembly_table =  "  <table style=i\"float: left\">
    <tr>
    	<th>Assembly</th>
        <th>Source</th>
    </tr>"

f = false
linenum =0
previous_key= "" #tracks the previous key (file that source line is in) 
assembly.each_line do |line|
  linenum = linenum + 1 
  linenum_string = linenum.to_s
  linenum_string= linenum_string + ". "
  tmp = line.strip
  line =line.gsub("<", "&lt").gsub(">", "&gt")
  arr = line.gsub(/\s/m, ' ').strip.split(" ")
  addr = arr[0]
  if !addr.nil? == true && addr.match(/:/)
    addr = addr.gsub(/:/, '')
  lookup_table.each do |key, value|
    asmly_addr = value.keys
    asmly_addr.each do |item|
      puts "LOOK OVER HERE"
      current_source_line = value[item][0].to_i #current source line being checked
      if item.kind_of?(Array)
        if item[0].match(/#{addr}/)
          if item[0].match(/&ltmain&gt/)
            assembly_table += "<tr><td><a id=\"target\"></a>"
          else
            assembly_table += "<tr><td>"
          end
          #puts "#{tmp}                               #{'c:'+value[item]}"
          if key.eql? previous_key
          else
           assembly_table += "<tr><td>~</td><td>#{key}</td></tr><tr><td>"
          end
          previous_key = key
          assembly_table = assembly_table +"#{linenum_string}#{tmp}</td><td>#{value[item]}</td></tr>" #add new row to table with "assembly => source"
          f = true
          #check if next source code lines do not have corresponding assembly lines
          more_lines = true #remains true as long as the next source line does not have corresponding assembly lines
          while more_lines
            current_source_line= current_source_line +1
            if unused_table.key?(key)
              source_lines= unused_table[key]
              if source_lines.key?(current_source_line)
                 assembly_table += "<tr><td>~</td><td>#{source_lines[current_source_line]}</td></tr><tr><td>"#create new table row to display unused source code
              else
                 more_lines = false
              end
            end
          end #end of while loop
        end
      else
        if item.match(/#{addr}/)
          if item.match(/&ltmain&gt/)
            assembly_table += "<tr><td><a id=\"target\"></a>"
          else
            assembly_table += "<tr><td>"
          end
          #puts "#{tmp}                               #{'c:'+value[item]}"
          if key.eql? previous_key
          else
            assembly_table += "<tr><td>~</td><td>#{key}</td></tr><tr><td>"
          end
          previous_key = key
          assembly_table = assembly_table +"#{linenum_string}#{tmp}</td><td>#{value[item]}</td></tr>"
          f = true
          #check if next source code lines do not have corresponding assembly lines
          more_lines = true #remains true as long as the next source line does not have corresponding assembly lines
          while more_lines
            current_source_line = current_source_line + 1
            if unused_table.key?(key) 
              source_lines= unused_table[key]
              if source_lines.key?(current_source_line)
                 assembly_table += "<tr><td>~</td><td>#{source_lines[current_source_line]}</td></tr><tr><td>"#create new table row to display unused source code
              else
                 more_lines = false
              end
            end
          end #end of while loop
        end
      end #end of if/else
    end #end of item loop
  end #end of |key,value| loop
  end
 if f == false
   puts line
   if line.match(/&ltmain&gt/)
            assembly_table += "<tr><td><a id=\"target\"></a>"
   else
      assembly_table += "<tr><td>"
   end
   assembly_table = assembly_table  +linenum_string+ line + "</td></tr>"
 end
 f = false
end
result = result + assembly_table + "<a href=\"#target\">Link</a>
</div>
        </body>
    </html>"
puts "HTML CODE GENERATED:"
puts result

#Create directory and write html files
Dir.mkdir('html') unless Dir.exist?('html') #creates directory if it does not already exist
File.open('html/output.html','w') do |file|
  file.write(result) 
end
