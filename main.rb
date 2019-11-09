#this function read the llvm-dwarfdump output and analyze it, then return two tables.
#the first returned table is new_lookup_table, which stores the source code file name, their assembly address and corresponding source code
#the second returned table is unused_source_code, which stores all the source code that has no corresponding assembly code, e.g., comments
def readdwarf(dwarf_file)
  lookup_table = {}
  #new_lookup_table {file_1: {0x0001=>first source code line, [0x0002, 0x0003]=>second source code line}
  #                  file_2: {0x0006=>first source code line, [0x0008, 0x0009]=>second source code line}} 
  new_lookup_table = {}
  #file_indexes stores the file indexes, e.g., the index of test.c is 1, so we store 1 into this array 
  file_indexes = []
  #file_names stores the file names, e.g., we store the "test.c" into this array
  file_names = []
  #this part initializes the lookup_table, which finally looks like 
  #.   {file_1: {assembly_addr_1=>line_number_1, assembly_addr_2=>line_number_2 ...}
  #     file_2: {assembly_addr_1=>line_number_1, assembly_addr_2=>line_number_2... }
  #     .....}
  dwarf_file.each_line do |line|
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
lookup_table.each do |key, value|
  #puts "#{key}: #{value}"
  new_value = {}
  value.each do |k, v|
    if value.select{|k_1, v_1| v_1 == v}.keys.length > 1
      new_value[value.select{|k_1, v_1| v_1 == v}.keys] = value[k]+". "+IO.readlines(key)[v.to_i-1]
    else
      new_value[k] = value[k] +". "+ IO.readlines(key)[v.to_i-1]
    end
  end
  new_value = new_value
  new_lookup_table[key] = new_value
end

=begin
new_lookup_table.each do |k, v|
  puts "#{k} \n"
  v.each do |key, value|
    puts "#{key}- #{value} \n"
  end
end
<<<<<<< HEAD
=end
=begin
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
          puts "#{tmp}                               #{'c:'+value[item]}"
          f = true
        end
      else
        if item.match(/#{addr}/)
          puts "#{tmp}                               #{'c:'+value[item]}"
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
=end

unused_source_code = {}

  lookup_table.each do |file, code_line_number|
    line_num = 0
    source_code = File.open(file).read
    source_code.gsub!(/\r\n?/, "\n")
    source_code.each_line do |code|
      line_num = line_num + 1
      if !code_line_number.values.include? line_num
        if unused_source_code.has_key?(file)
          value = unused_source_code[file]
          value[line_num] = code
          unused_source_code[file] = value
        else
          unused_source_code[file] = {line_num => code}
        end
      end
    end
  end
  return [new_lookup_table, unused_source_code]
end
#File.readlines('ASSEMBLY').each do |line|
#  new_loopup_table.each do |key, value|
#    if line.match()
#end
