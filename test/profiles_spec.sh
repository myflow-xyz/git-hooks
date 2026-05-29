Describe 'profiles'
  It 'only defines supported hook phases and executable check IDs'
    When run sh -u -c '
      ROOT=$1
      set -e

      for profile_dir in "$ROOT"/profiles/*; do
        [ -d "$profile_dir" ] || continue
        profile_name=${profile_dir##*/}

        for list_file in "$profile_dir"/*.list; do
          [ -f "$list_file" ] || continue
          phase_name=${list_file##*/}
          phase_name=${phase_name%.list}

          case "$phase_name" in
          pre-commit | pre-push | commit-msg)
            ;;
          *)
            printf "%s\n" "unsupported profile phase: $profile_name/$phase_name" >&2
            exit 1
            ;;
          esac

          while IFS= read -r check_id || [ -n "$check_id" ]; do
            check_id=$(printf "%s\n" "$check_id" | sed '"'"'s/^[[:space:]]*//; s/[[:space:]]*$//'"'"')
            case "$check_id" in
            "" | \#*)
              continue
              ;;
            esac

            check_path=$ROOT/lib/checks/${check_id%.sh}.sh
            if [ ! -x "$check_path" ]; then
              printf "%s\n" "profile check is not executable: $profile_name/$phase_name -> $check_path" >&2
              exit 1
            fi
          done < "$list_file"
        done
      done
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
  End

  It 'runs codegraph index last in development-heavy pre-push profiles'
    When run sh -u -c '
      ROOT=$1
      set -e

      for profile_name in golang react-vite; do
        list_file=$ROOT/profiles/$profile_name/pre-push.list
        last_check=$(tail -n 1 "$list_file")
        if [ "$last_check" != "dev/codegraph-build-index" ]; then
          printf "%s\n" "codegraph-build-index is not last: $profile_name" >&2
          exit 1
        fi
      done
    ' sh "$SHELLSPEC_PROJECT_ROOT"
    The status should eq 0
  End
End
