use dirs::home_dir;
use md5;
use std::fs::{metadata, read_dir, remove_file, File};
use std::io::prelude::*;
use x11_clipboard::Clipboard;

fn main() {
    let clipboard = Clipboard::new().unwrap();
    let mut last = String::new();
    let yank_history_max_size = 20;
    let yank_history_dir = format!(
        "{}/.local/share/yank_history/",
        home_dir().unwrap().to_string_lossy()
    );

    loop {
        if let Ok(curr) = clipboard.load_wait(
            clipboard.getter.atoms.clipboard,
            clipboard.getter.atoms.utf8_string,
            clipboard.getter.atoms.property,
        ) {
            let curr = String::from_utf8_lossy(&curr);
            let curr = curr.trim_matches('\u{0}').trim();
            if !curr.is_empty() && last != curr {
                last = curr.to_owned();
                let digest = md5::compute(&last);
                println!("{:?}", digest);
                let path = format!("{}/{:?}.", &yank_history_dir, &digest);
                let mut file = File::create(path).unwrap();
                file.write_all(last.as_bytes()).unwrap();
                let paths = read_dir(&yank_history_dir).unwrap();
                let num_yanks = paths.count();
                let mut min_last_modified = None;
                let mut last_modified_path = None;
                if yank_history_max_size > 0 && num_yanks > yank_history_max_size {
                    for entry in read_dir(&yank_history_dir).unwrap() {
                        let entry = entry.unwrap();
                        let path = entry.path();

                        let meta = metadata(&path).unwrap();
                        let last_modified = meta.modified().unwrap().elapsed().unwrap().as_secs();
                        min_last_modified = match min_last_modified {
                            Some(old_min) => {
                                if last_modified > old_min {
                                    last_modified_path = Some(path);
                                    Some(last_modified)
                                } else {
                                    min_last_modified
                                }
                            }
                            None => {
                                last_modified_path = Some(path);
                                Some(last_modified)
                            }
                        }
                    }
                }
                if let Some(to_remove) = last_modified_path {
                    println!("removing {:?}", to_remove);
                    remove_file(to_remove).ok();
                }
            }
        }
    }
}
