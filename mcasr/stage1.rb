#!/usr/bin/env ruby

# Usage: ./stage1.rb < uzb-clips.txt > stage1.txt

# Reads mcasr's uzb-clips.txt, which comes from
#
#     /ws/ifp-53_1/hasegawa/tools/kaldi/kaldi/src/bin/ali-to-phones exp/Uzbek/mono/final.mdl ark:'gunzip -c exp/Uzbek/mono_ali/ali.*.gz|' ark,t:- | utils/int2sym.pl -f 2- data/Russian/lang/phones.txt - > uzb-clips.txt
#
# Reformats that as one line per mp3 clip, with #-delimited transcriptions.
# Removes _B _E _I _S suffixes from phones, because word boundaries are meaningless for nonsense words.
#
# Does *not* trim off leading or trailing SIL silence and SPN speaker noise,
# because those help PTgen score and align transcriptions.
# Does *not* remove duplicate transcriptions, for the same reason.

# Maybe todo: remove consecutive duplicate phones, esp. SPN and SIL.  They're in 3% of transcriptions.

raw = ARGF.readlines .map {|l| l.split}

clips = Hash.new {|h,k| h[k] = []} # Map each clip-name to an array of transcriptions.

raw.each {|l|
  name = l[0][0..-5]
  scrip = l[1..-1].map {|p| p.sub /_[BEIS]/, ''}
  clips[name] << scrip

  if false
    # Report consecutive duplicate phones.
    f = false
    (scrip.size-1).times {|i| f |= scrip[i]==scrip[i+1]}
    puts "#{name} #{scrip}" if f
  end
}

# Sort the hash, to be pretty.
clips = clips.to_a.sort_by {|c| c[0]} .map {|name,ss| [name,ss.sort]}

# Convert each phone to its index in phones.txt.
# As a string, not an int, for easier join()ing.
phones = {}
File.readlines("phones.txt") .map {|l| l.split} .each {|p,i| phones[p] = i}

clips.map! {|name,ss| [name, ss.map {|ss| ss.map {|s| phones[s]} .join(" ")}]}
clips.each {|name,ss| puts "#{name}:#{ss.join ' # '}" }
