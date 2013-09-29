open JavaScript

let () =
  match Array.to_list Sys.argv with
  | [ _; "parse"; path ] ->
    (try 
       let _  = parse_javascript_from_channel (open_in path) path in
       ()
     with exn ->
      (Format.printf "Exception parsing %s (%s)\n%!" path (Printexc.to_string exn);
       exit 2))
  | _ -> 
    Format.eprintf "Invalid command line arguments\n%!";
    exit 2