%{

package parser

import (
    "github.com/skydb/skygen/core"
    "strings"
    "time"
)

%}

%union{
    token int
    integer int
    boolean bool
    duration time.Duration
    duration_range []time.Duration
    str string
    strs []string
    script *core.Script
    schema *core.Schema
    property *core.Property
    properties core.Properties
    event *core.Event
    events core.Events
    value_sets core.ValueSets
    value_set *core.ValueSet
    key_values map[string]interface{}
    key_value key_value
}

%token <token> TSTARTSCRIPT
%token <token> TEVENT, TEND, TAFTER, TWEIGHT, TSET, TPROBABILITY
%token <token> TSCHEMA, TPROPERTY, TTRANSIENT, TEXIT
%token <token> TTRUE, TFALSE
%token <token> TMINUS, TCOMMA, TEQUALS
%token <str> TIDENT, TSTRING
%token <integer> TDURATIONYEAR, TDURATIONDAY, TDURATIONHOUR
%token <integer> TDURATIONMINUTE, TDURATIONSECOND
%token <integer> TINT, TPERCENT

%type <script> script
%type <schema> schema
%type <property> property
%type <properties> properties
%type <boolean> property_transient
%type <event> event
%type <events> events
%type <integer> event_weight, event_exit_probability
%type <integer> probability
%type <duration_range> event_after
%type <duration> duration_year, duration_day, duration_hour
%type <duration> duration_minute, duration_second
%type <duration> duration

%type <value_sets> value_sets
%type <value_set> value_set
%type <key_values> key_values
%type <key_value> key_value

%start start

%%

start :
    TSTARTSCRIPT script
    {
        l := yylex.(*yylexer)
        l.script = $2
    }
;

script :
    schema events
    {
        $$ = core.NewScript()
        $$.SetSchema($1)
        $$.SetEvents($2)
    }
;

schema :
    /* empty */
    {
        $$ = nil
    }
|   TSCHEMA properties TEND
    {
        $$ = core.NewSchema()
        $$.Properties = $2
    }
;

properties :
    /* empty */
    {
        $$ = make(core.Properties, 0)
    }
|   properties property
    {
        $$ = append($1, $2)
    }
;

property :
    TPROPERTY TIDENT TIDENT property_transient
    {
        $$ = core.NewProperty()
        $$.Name = $2
        $$.DataType = strings.ToLower($3)
        $$.Transient = $4
    }
;

property_transient :
    /* empty */ { $$ = false }
|   TTRANSIENT  { $$ = true }
;

events :
    /* empty */
    {
        $$ = make(core.Events, 0)
    }
|   events event
    {
        $$ = append($1, $2)
    }
;

event :
    TEVENT event_after event_weight event_exit_probability value_sets events TEND
    {
        $$ = core.NewEvent()
        $$.After = $2
        $$.Weight = $3
        $$.ExitProbability = $4
        $$.SetValueSets($5)
        $$.SetEvents($6)
    }
;

event_after :
    /* empty */
    {
        $$ = []time.Duration{}
    }
|   TAFTER duration TMINUS duration
    {
        $$ = []time.Duration{$2, $4}
    }
|   TAFTER duration
    {
        $$ = []time.Duration{$2, $2}
    }
;

event_weight :
    /* empty */
    {
        $$ = 1
    }
|   TWEIGHT TINT
    {
        $$ = $2
    }
;

event_exit_probability :
    /* empty */  { $$ = 0 }
|   TEXIT probability { $$ = $2 }
;

value_sets :
    /* empty */
    {
        $$ = make(core.ValueSets, 0)
    }
|   value_sets value_set
    {
        $$ = append($1, $2)
    }
;

value_set :
    TSET key_values probability
    {
        $$ = core.NewValueSet()
        $$.Values = $2
        $$.Probability = $3
    }
;

key_values :
    /* empty */
    {
        $$ = make(map[string]interface{})
    }
|   key_value
    {
        $$ = make(map[string]interface{})
        $$[$1.key] = $1.value
    }
|   key_values TCOMMA key_value
    {
        $1[$3.key] = $3.value
    }
;

key_value :
    TIDENT TEQUALS TSTRING
    {
        $$.key = $1
        $$.value = $3
    }
;


probability :
    /* empty */
    {
        $$ = 100
    }
|   TPROBABILITY TPERCENT
    {
        $$ = $2
    }
;

duration :
    duration_year duration_day duration_hour duration_minute duration_second
    {
        $$ = $1 + $2 + $3 + $4 + $5
    }
;

duration_year :
    /* empty */   { $$ = 0 * time.Hour }
|   TDURATIONYEAR { $$ = time.Duration($1 * 24 * 365) * time.Hour }
;

duration_day :
    /* empty */   { $$ = 0 * time.Hour }
|   TDURATIONDAY  { $$ = time.Duration($1 * 24) * time.Hour }
;

duration_hour :
    /* empty */    { $$ = 0 * time.Hour }
|   TDURATIONHOUR  { $$ = time.Duration($1) * time.Hour }
;

duration_minute :
    /* empty */      { $$ = 0 * time.Minute }
|   TDURATIONMINUTE  { $$ = time.Duration($1) * time.Minute }
;

duration_second :
    /* empty */      { $$ = 0 * time.Second }
|   TDURATIONSECOND  { $$ = time.Duration($1) * time.Second }
;

%%

type key_value struct {
    key string
    value interface{}
}
