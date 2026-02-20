import json
import os.path
import subprocess
import sys

from argparse import ArgumentParser
from dataclasses import asdict, dataclass, field, replace
from datetime import datetime, timedelta, timezone
from tkinter import Entry, Label, Listbox, E, END, LEFT, W
from tkinter.simpledialog import Dialog
from typing import List, Optional, TypedDict


def transform(self, ignore=[], **kwargs):
  return {**{ k: v for k,v in self.items() if k not in ignore }, **{ prop: transformer(self.get(prop, None)) for prop, transformer in kwargs.items()}}

def listof(transformer):
  def transform(value):
    return list(map(transformer, value))
  return transform

def withdefault(transformer, default):
  def transform(value):
    return default if value is None else transformer(value)
  return transform

def isostring(value):
  return datetime.fromisoformat(value)

@dataclass
class Data:
  tasks: List[Task]

  @classmethod
  def fromjson(cls, raw):
    return cls(**transform(raw, tasks=withdefault(listof(Task.fromjson), [])))

@dataclass
class Task:
  name: str
  status_since: datetime
  status_attested_at: datetime
  blocked: Optional[Blocked] = None

  @classmethod
  def fromjson(cls, raw):
    return cls(**transform(raw, blocked=withdefault(Blocked.fromjson, None), status_since=withdefault(isostring, _long_ago), status_attested_at=withdefault(isostring, _long_ago)))

@dataclass
class Blocked:
  by: str

  @classmethod
  def fromjson(cls, raw):
    return cls(**transform(raw))

_long_ago = datetime(1900,1,10,tzinfo=timezone.utc)

class CustomDialog(Dialog):

  def __init__(self, prompt):
    self._prompt = prompt
    self.accepted = False

    Dialog.__init__(self, None, "Context")

    if not self.accepted:
      print("Aborted by user")
      sys.exit(1)

  def body(self, master):
    # After a minute with no interaction, abort.
    # This would make more sense in __init__, but this is the most sensible
    # hook we have after super.super.__init__ is called but before we block on
    # the dialog showing.
    self.after(60_000, self.cancel)
    self.bind('<KP_Enter>', self.ok)

    w = Label(master, text=self._prompt, justify=LEFT)
    w.grid(row=0, padx=5, sticky=W)

    return self.widget(master)

  def apply(self):
    self.accepted = True

class ChoicesDialog(CustomDialog):
  def __init__(self, prompt, values=[]):
    self._values = list(values)

    CustomDialog.__init__(self, prompt)

  def widget(self, master):
    self._listbox = Listbox(master)
    self._listbox.insert(END, *map(lambda x: x[0], self._values))
    self._listbox.activate(0)
    self._listbox.selection_set(0)
    self._listbox.grid(row=1, padx=5, sticky=W+E)

    return self._listbox

  def validate(self):
    self.result = self._values[self._listbox.curselection()[0]][1]
    return 1

class StringDialog(CustomDialog):
  def __init__(self, prompt):
    CustomDialog.__init__(self, prompt)

  def widget(self, master):
    self._entry = Entry(master, name="entry")
    self._entry.grid(row=1, padx=5, sticky=W+E)

    return self._entry

  def validate(self):
    self.result = self._entry.get()
    return 1

def choices(prompt, values):
  return ChoicesDialog(prompt, values).result

def inputstring(prompt):
  return StringDialog(prompt).result

def default_serial(obj):
  if isinstance(obj, datetime):
    return obj.isoformat()
  return json.JSONEncoder.default(obj)

def write(datafile, data):
  with open(datafile, "w") as f:
    new_file_contents = subprocess.check_output(['/opt/homebrew/bin/yq', '-p=json', '-o=yaml'], input=json.dumps(asdict(data), default=default_serial).encode('utf-8')).decode('utf-8')
    print("Updated file contents:")
    print(new_file_contents)
    f.write(new_file_contents)

def main(datafile, unattest):
  now = datetime.now(timezone.utc)
  if not os.path.isfile(datafile):
    basedir = os.path.dirname(datafile)
    if not os.path.exists(basedir):
      os.makedirs(basedir)
    with open(datafile, "w") as f:
      pass
  with open(datafile, "r") as f:
    initial_file_contents = f.read()
  print("Initial file contents:")
  print(initial_file_contents)
  sys.stdout.flush()
  data = Data.fromjson(json.loads(subprocess.check_output(['/opt/homebrew/bin/yq', '-o=json', '. // {}'], input=initial_file_contents.encode('utf-8'))))
  new_data = None
  if unattest and any(task.status_attested_at != _long_ago for task in data.tasks):
    new_data = data = Data(tasks=[replace(task, status_attested_at=_long_ago) for task in data.tasks])
  while True:
    step = process(data, now)
    if step is None:
      break
    else:
      new_data = data = step
  if new_data is None:
    print("No changes")
  else:
    write(datafile, new_data)

def process(data, now):
  def work_on_something(prompt):
    match choices(prompt, [(task.name, index) for index, task in enumerate(data.tasks)] + [("Something else", -1)]):
      case -1:
        return Data(tasks=[Task(name=inputstring(prompt), status_since=now, status_attested_at=now)] + data.tasks)
      case selected_index:
        insertion_index = next((i for i, task in enumerate(data.tasks) if not task.blocked and i < selected_index), selected_index)
        return Data(tasks=data.tasks[0:insertion_index] + [replace(data.tasks[selected_index], blocked=None, status_since=now, status_attested_at=now)] + data.tasks[insertion_index:selected_index] + data.tasks[selected_index+1:])
  for index, task in enumerate(data.tasks):
    if task.blocked is not None:
      if now < task.status_attested_at + timedelta(minutes=2):
        continue
      if choices(f"Is {task.name} still blocked by {task.blocked.by}?", _yesno):
        return Data(tasks=data.tasks[0:index] + [replace(data.tasks[index], status_attested_at=now)] + data.tasks[index+1:])
      else:
        return Data(tasks=data.tasks[0:index] + [replace(data.tasks[index], blocked=None, status_since=now, status_attested_at=_long_ago)] + data.tasks[index+1:])
    else:
      if now < task.status_attested_at + timedelta(minutes=10):
        return
      match choices(f"Are you still working on {task.name}?", [("Yes", 'working'), ("No, it's blocked", 'blocked'), ("No, it's done", 'done'), ("No, I'm doing something more important", "important"), ("No, I got off track", 'derailed')]):
        case 'working':
          return Data(tasks=data.tasks[0:index] + [replace(data.tasks[index], status_attested_at=now)] + data.tasks[index+1:])
        case 'blocked':
          return Data(tasks=data.tasks[0:index] + [replace(data.tasks[index], blocked=Blocked(by=inputstring(f"What is {task.name} blocked on?")), status_since=now, status_attested_at=now)] + data.tasks[index+1:])
        case 'done':
          return Data(tasks=data.tasks[0:index] + data.tasks[index+1:])
        case 'important':
          return work_on_something("What are you working on?")
        case 'derailed':
          return work_on_something("What are you going to work on now?")
  else:
    return Data(tasks=data.tasks + [Task(name=inputstring("What are you working on?"), status_since=now, status_attested_at=now)])

_yesno = [("Yes", True), ("No", False)]
  
if __name__ == '__main__':
  parser = ArgumentParser()
  parser.add_argument('datafile')
  parser.add_argument('--unattest', action='store_true')
  args = parser.parse_args()
  main(**vars(args))
