let indent s in_lines = s

let textarea textbox =
  let rec loop s acc (i,pos') =
    try
      let pos = String.index_from s pos' '\n' in
      loop s ((i,(pos',pos))::acc) (succ i,succ pos)
    with _ -> List.rev ((i,(pos',String.length s)) :: acc) in
  let rec find (l : (int * (int * int)) list ) c =
    match l with
    | [] -> assert false
    | (i,(lo,up))::_ when up >= c -> c,i,lo,up
    | (_,(lo,up))::rem -> find rem c in
  let v = textbox##value in
  let pos =
    let c1 = (Js.Unsafe.coerce textbox)##selectionStart
    and c2 = (Js.Unsafe.coerce textbox)##selectionEnd in
    if Js.Opt.test (Js.Opt.return c1) && Js.Opt.test (Js.Opt.return c2)
    then begin
	let l = loop (Js.to_string v) [] (0,0) in
	Some (find l c1,find l c2)
      end
    else None in
  let f = match pos with
    | None -> (fun _ -> true)
    | Some ((c1,line1,lo1,up1),(c2,line2,lo2,up2)) -> (fun l -> l>=(line1+1) && l<=(line2+1)) in
  let v = indent (Js.to_string v) f in
  textbox##value<-Js.string v;
  begin
    match pos with
    | Some ((c1,line1,lo1,up1),(c2,line2,lo2,up2)) ->
       let l = loop v [] (0,0) in
       let (lo1'',up1'') = List.assoc line1 l in
       let (lo2'',up2'') = List.assoc line2 l in
       let n1 = max (c1 + up1'' - up1) lo1'' in
       let n2 = max (c2 + up2'' - up2) lo2'' in
       let () = (Js.Unsafe.coerce textbox)##setSelectionRange(n1,n2) in
       textbox##focus();
       ()
    | None -> ()
  end
