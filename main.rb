#this part generates a lookup_table
#lookup_table stores {file_1: {assembly_addr_1=>source_code_line_1, assembly_addr_2=>source_code_line_2 ...}
#                     file_2: {assembly_addr_1=>source_code_line_1, assembly_addr_2=>source_code_line_2... }
#                     ......}
lookup_table = {}
file_indexes = []
file_names = []
flag = false

File.readlines('DWARF').each do |line|
    if flag == false
      if line.match(/file_names/)
        file_index = line.scan(/\d/).join('').to_s
        file_indexes.push(file_index)
      elsif line.match(/name:/)
        file_name = line.scan(/"[^"]*"/).to_s.gsub('"', '').gsub("\\", '')
        file_names.push(file_name)
      elsif line.match(/Discriminator/)
        flag = true
      end 
    end
    if flag == true
      if line.match(/\d+/)
        arr = line.gsub(/\s+/m, ' ').strip.split(" ")
        assembly_addr = arr[0]
        line_number = arr[1]
        file = file_names[arr[3].to_i-1].gsub("[", '').gsub("]", '')
        if lookup_table.has_key?(file)
          value = lookup_table[file]
          value[assembly_addr] = line_number
          lookup_table[file] = value
        else
          lookup_table[file] ={assembly_addr => line_number}
        end 
      end 
    end 
end

#this part processes the lookup_table which is generated from the previous part, replaces the line_number by the source code in the corresponding source file. If multiple assembly code lines refer to the same source code line, then grouping all the assembly code lines together to form a new key, and the value is the source code line. 
#e.g., lookup_table {file_1: {0x0001=>1, 0x0002=>2, 0x0003=>2}}
#      new_lookup_table {file_1: {0x0001=>first source code line, [0x0002, 0x0003]=>second source code line}} 
new_lookup_table = {}
lookup_table.each do |key, value|
  #puts "#{key}: #{value}"
  new_value = {}
  value.each do |k, v|
    if value.select{|k_1, v_1| v_1 == v}.keys.length > 1
      new_value[value.select{|k_1, v_1| v_1 == v}.keys] = IO.readlines(key)[v.to_i-1]
    else
      new_value[k] = IO.readlines(key)[v.to_i-1]
    end
  end
  new_lookup_table[key] = new_value
end

=begin
new_lookup_table.each do |k, v|
  puts "#{k} \n"
  v.each do |key, value|
    puts "#{key}- #{value} \n"
  end
end
=end
f = false
File.readlines('ASSEMBLY').each do |line|
  tmp = line.strip
  arr = line.gsub(/\s/m, ' ').strip.split(" ")
  addr = arr[0] 
  if !addr.nil? == true && addr.match(/:/)
    addr = addr.gsub(/:/, '')
  new_lookup_table.each do |key, value|
    asmly_addr = value.keys
    asmly_addr.each do |item|
      if item.kind_of?(Array)
        if item[0].match(/#{addr}/) 
          puts "#{tmp}                               #{value[item]}"
          f = true
        end
      else
        if item.match(/#{addr}/)
          puts "#{tmp}                               #{value[item]}"
          f = true
        end 
      end
    end
  end
  end 
 if f == false
   puts line
 end 
 f = false
end
